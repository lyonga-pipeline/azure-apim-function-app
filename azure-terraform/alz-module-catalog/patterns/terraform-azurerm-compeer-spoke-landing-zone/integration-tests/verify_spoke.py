#!/usr/bin/env python3
"""Read Azure's observed state; optionally prove private, managed-identity secret access."""

import argparse
import ipaddress
import json
import secrets
import socket
import subprocess
import sys
import time
import uuid
from urllib.parse import urlparse


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def az_json(*arguments):
    result = subprocess.run(
        ["az", *arguments, "--output", "json", "--only-show-errors"],
        capture_output=True, text=True, check=False, timeout=90,
    )
    if result.returncode:
        raise RuntimeError("Azure read failed: " + result.stderr.strip())
    return json.loads(result.stdout)


def verify_control_plane(contract, command=az_json):
    require(contract.get("contract_version") == "1.0.0", "Unsupported spoke contract version")

    def get(resource_id, version="2024-05-01"):
        url = f"https://management.azure.com{resource_id}?api-version={version}"
        return command("rest", "--method", "get", "--url", url)

    vault_id = contract["key_vault"]["id"]
    vault = get(vault_id, "2023-07-01")["properties"]
    require(vault.get("enableRbacAuthorization") is True, "Vault RBAC is not enabled")
    require(vault.get("publicNetworkAccess") == "Disabled", "Vault public access is not disabled")
    require(vault.get("enablePurgeProtection") is True, "Vault purge protection is not enabled")
    require(vault.get("softDeleteRetentionInDays") == 90, "Vault soft-delete retention is not 90 days")
    require(vault.get("networkAcls", {}).get("defaultAction") == "Deny", "Vault ACLs are not deny-by-default")
    require(vault.get("networkAcls", {}).get("bypass") == "None", "Unexpected vault service bypass")

    private_prefixes = []
    for key, subnet_id in contract["subnet_ids"].items():
        subnet = get(subnet_id)["properties"]
        require(subnet.get("defaultOutboundAccess") is False, f"Implicit outbound access on {key}")
        require(subnet.get("privateEndpointNetworkPolicies") == "Enabled", f"Private endpoint policies disabled on {key}")
        nsg_id = subnet.get("networkSecurityGroup", {}).get("id")
        route_id = subnet.get("routeTable", {}).get("id")
        require(nsg_id and route_id, f"Missing NSG/route association on {key}")
        rules = get(nsg_id)["properties"].get("securityRules", [])
        for direction in ("Inbound", "Outbound"):
            require(any(
                rule["properties"].get("direction") == direction
                and rule["properties"].get("access") == "Deny"
                and rule["properties"].get("priority") == 4096
                for rule in rules
            ), f"Missing default deny {direction} on {key}")
        route_properties = get(route_id)["properties"]
        require(route_properties.get("disableBgpRoutePropagation") is True, f"Gateway BGP bypass enabled on {key}")
        routes = route_properties.get("routes", [])
        for prefix in ["0.0.0.0/0", *contract["security_baseline"].get("inspection_address_prefixes", [])]:
            require(any(
                route["properties"].get("addressPrefix") == prefix
                and route["properties"].get("nextHopType") == "VirtualAppliance"
                and route["properties"].get("nextHopIpAddress") == contract["security_baseline"]["egress_next_hop_ip"]
                for route in routes
            ), f"Missing approved inspected route {prefix} on {key}")
        if key == "private_endpoints":
            private_prefixes = subnet.get("addressPrefixes", []) or [subnet["addressPrefix"]]
            require(not subnet.get("delegations"), "Private endpoint subnet is delegated")

    attachment = contract["attachment_contract"]
    hub_id = attachment["hub_virtual_network_id"]
    spoke_id = contract["spoke_virtual_network_id"]
    for local_id, remote_id in ((hub_id, spoke_id), (spoke_id, hub_id)):
        peerings = get(local_id + "/virtualNetworkPeerings").get("value", [])
        require(any(
            peer["properties"].get("remoteVirtualNetwork", {}).get("id", "").lower() == remote_id.lower()
            and peer["properties"].get("peeringState") == "Connected"
            and peer["properties"].get("allowForwardedTraffic") is True
            for peer in peerings
        ), "A reciprocal, connected peering with forwarded traffic is missing")

    endpoint_id = contract["key_vault"]["private_endpoint_id"]
    endpoint = get(endpoint_id)["properties"]
    require(endpoint.get("subnet", {}).get("id", "").lower() == contract["subnet_ids"]["private_endpoints"].lower(), "Vault endpoint uses the wrong subnet")
    connections = endpoint.get("privateLinkServiceConnections", [])
    require(any(
        connection["properties"].get("privateLinkServiceId", "").lower() == vault_id.lower()
        and connection["properties"].get("groupIds") == ["vault"]
        and connection["properties"].get("privateLinkServiceConnectionState", {}).get("status") == "Approved"
        for connection in connections
    ), "Vault private endpoint connection is not approved")
    zone_id = attachment["key_vault_private_dns_zone_id"]
    group = get(endpoint_id + "/privateDnsZoneGroups/default")["properties"]
    require(any(
        item["properties"].get("privateDnsZoneId", "").lower() == zone_id.lower()
        for item in group.get("privateDnsZoneConfigs", [])
    ), "Private endpoint is not registered in the approved DNS zone")
    links = get(zone_id + "/virtualNetworkLinks", "2020-06-01").get("value", [])
    require(any(
        link["properties"].get("virtualNetwork", {}).get("id", "").lower() == spoke_id.lower()
        and link["properties"].get("registrationEnabled") is False
        for link in links
    ), "Spoke is not linked to the approved private zone")

    diagnostics = get(vault_id + "/providers/Microsoft.Insights/diagnosticSettings", "2021-05-01-preview").get("value", [])
    matching = [item for item in diagnostics
                if item["properties"].get("workspaceId", "").lower() == contract["diagnostic_ownership"]["workspace_id"].lower()
                and any(log.get("enabled") is True and log.get("category") == "AuditEvent" for log in item["properties"].get("logs", []))]
    require(len(matching) == 1, "Expected one central AuditEvent setting; missing/duplicate ownership must be reviewed")
    roles = command("role", "assignment", "list", "--scope", vault_id)
    require(any(
        role.get("scope", "").lower() == vault_id.lower()
        and role.get("principalId", "").lower() == contract["workload_identity"]["principal_id"].lower()
        and role.get("roleDefinitionName") == "Key Vault Secrets User"
        for role in roles
    ), "Workload identity does not have vault-scoped Secrets User access")
    verify_application_services(contract, get)
    return private_prefixes


def verify_application_services(contract, get):
    services = contract["application_services"]
    profile = contract["environment_profile"]
    workspace_id = contract["diagnostic_ownership"]["workspace_id"]
    if services.get("application_insights_id"):
        insights = get(services["application_insights_id"], "2020-02-02")["properties"]
        require(insights.get("DisableLocalAuth") is True, "Application Insights local/key authentication is enabled")
        require(insights.get("WorkspaceResourceId", "").lower() == workspace_id.lower(), "Application Insights uses the wrong central workspace")
        require(insights.get("SamplingPercentage") == profile["telemetry_sampling_percentage"], "Telemetry sampling differs from the resolved environment profile")

    if services.get("failed_requests_alert_id"):
        require(services.get("application_insights_id"), "Application alert requires enabled telemetry")
        alert = get(services["failed_requests_alert_id"], "2018-03-01")["properties"]
        require(alert.get("enabled") is True and alert.get("severity") == profile["alert_severity"], "Application failure alert is disabled or has the wrong severity")
        destinations = {action.get("actionGroupId", "").lower() for action in alert.get("actions", [])}
        require(destinations and destinations == {item.lower() for item in services["action_group_ids"]}, "Application alert has missing/wrong destinations")
    if services.get("budget_id"):
        budget = get(services["budget_id"], "2023-05-01")["properties"]
        require(budget.get("amount") == services["budget_amount"], "Budget does not match the approved amount")
        notifications = list(budget.get("notifications", {}).values())
        for threshold, kind in [(80, "Actual"), (100, "Actual"), (100, "Forecasted")]:
            require(any(item.get("enabled") is True and item.get("threshold") == threshold and item.get("thresholdType") == kind
                        and item.get("contactGroups") for item in notifications), "Budget notification coverage is incomplete")

    for key, account in services.get("storage", {}).items():
        observed = get(account["id"], "2023-05-01")
        properties = observed["properties"]
        require(properties.get("publicNetworkAccess") == "Disabled" and properties.get("allowSharedKeyAccess") is False,
                f"Storage {key} is not private and keyless")
        require(properties.get("minimumTlsVersion") == "TLS1_2" and properties.get("supportsHttpsTrafficOnly") is True,
                f"Storage {key} does not enforce TLS/HTTPS")
        require(observed.get("sku", {}).get("name") == "Standard_" + account["replication_type"], f"Storage {key} replication differs from profile")
        blob = get(account["id"] + "/blobServices/default", "2023-05-01")["properties"]
        require(blob.get("isVersioningEnabled") is True and blob.get("deleteRetentionPolicy", {}).get("enabled") is True
                and blob.get("deleteRetentionPolicy", {}).get("days") == account["delete_retention_days"]
                and blob.get("containerDeleteRetentionPolicy", {}).get("enabled") is True
                and blob.get("containerDeleteRetentionPolicy", {}).get("days") == account["delete_retention_days"], f"Storage {key} recovery controls are missing")
        endpoint = get(account["private_endpoint_id"])["properties"]
        require(endpoint.get("subnet", {}).get("id", "").lower() == contract["subnet_ids"]["private_endpoints"].lower(), f"Storage {key} endpoint uses the wrong subnet")
        require(any(connection["properties"].get("privateLinkServiceId", "").lower() == account["id"].lower()
                    and connection["properties"].get("groupIds") == ["blob"]
                    and connection["properties"].get("privateLinkServiceConnectionState", {}).get("status") == "Approved"
                    for connection in endpoint.get("privateLinkServiceConnections", [])), f"Storage {key} private endpoint is not approved")
        zone_id = contract["attachment_contract"]["storage_blob_private_dns_zone_id"]
        group = get(account["private_endpoint_id"] + "/privateDnsZoneGroups/default")["properties"]
        require(any(item["properties"].get("privateDnsZoneId", "").lower() == zone_id.lower() for item in group.get("privateDnsZoneConfigs", [])), f"Storage {key} uses the wrong private DNS zone")
        links = get(zone_id + "/virtualNetworkLinks", "2020-06-01").get("value", [])
        require(any(link["properties"].get("virtualNetwork", {}).get("id", "").lower() == contract["spoke_virtual_network_id"].lower()
                    and link["properties"].get("registrationEnabled") is False for link in links), f"Storage {key} zone is not linked to the spoke")
        diagnostics = get(account["id"] + "/blobServices/default/providers/Microsoft.Insights/diagnosticSettings", "2021-05-01-preview").get("value", [])
        matching = [item for item in diagnostics if item["properties"].get("workspaceId", "").lower() == workspace_id.lower()
                    and {"StorageRead", "StorageWrite", "StorageDelete"}.issubset({log.get("category") for log in item["properties"].get("logs", []) if log.get("enabled") is True})]
        require(len(matching) == 1, f"Storage {key} Blob logs are missing or duplicated")


def verify_private_dns(vault_uri, prefixes, resolve=socket.getaddrinfo):
    hostname = urlparse(vault_uri).hostname
    require(hostname and hostname.endswith(".vault.azure.net"), "Expected an Azure public-cloud vault URI")
    networks = [ipaddress.ip_network(prefix) for prefix in prefixes]
    addresses = {ipaddress.ip_address(answer[4][0]) for answer in resolve(hostname, 443, socket.AF_INET, socket.SOCK_STREAM)}
    require(addresses and all(any(address in network for network in networks) for address in addresses),
            "Vault DNS does not resolve exclusively inside the private endpoint subnet from this runner")


def secret_roundtrip(writer, reader, retry=lambda operation: operation()):
    name = "integration-probe-" + uuid.uuid4().hex
    value = secrets.token_urlsafe(32)
    try:
        retry(lambda: writer.set_secret(name, value))
        observed = retry(lambda: reader.get_secret(name))
        require(observed.value == value, "Managed identity could not retrieve the ephemeral test secret")
    finally:
        # Delete, never purge. No application secret is read or modified.
        writer.begin_delete_secret(name).wait()


def retry_until(operation, deadline):
    while True:
        try:
            return operation()
        except Exception:
            if time.monotonic() >= deadline:
                raise
            time.sleep(5)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", default="-", help="terraform output -json spoke, or - for stdin")
    parser.add_argument("--private-dns", action="store_true", help="Require a network-connected runner and private vault DNS resolution")
    parser.add_argument("--secret-probe", action="store_true", help="Opt-in ephemeral secret round trip using separate operator and workload credentials")
    parser.add_argument("--timeout", type=int, default=600)
    args = parser.parse_args()
    with (sys.stdin if args.contract == "-" else open(args.contract, encoding="utf-8")) as source:
        contract = json.load(source)
    deadline = time.monotonic() + args.timeout
    prefixes = retry_until(lambda: verify_control_plane(contract), deadline)
    if args.private_dns or args.secret_probe:
        retry_until(lambda: verify_private_dns(contract["key_vault"]["uri"], prefixes), deadline)
    if args.secret_probe:
        from azure.identity import AzureCliCredential, ManagedIdentityCredential
        from azure.keyvault.secrets import SecretClient

        uri = contract["key_vault"]["uri"]
        with AzureCliCredential() as operator, ManagedIdentityCredential(client_id=contract["workload_identity"]["client_id"]) as workload:
            with SecretClient(uri, operator) as writer, SecretClient(uri, workload) as reader:
                secret_roundtrip(writer, reader, lambda operation: retry_until(operation, deadline))
    print(json.dumps({"control_plane": "passed", "private_dns": "passed" if args.private_dns or args.secret_probe else "not_run", "managed_identity_secret_access": "passed" if args.secret_probe else "not_run"}))


if __name__ == "__main__":
    main()
