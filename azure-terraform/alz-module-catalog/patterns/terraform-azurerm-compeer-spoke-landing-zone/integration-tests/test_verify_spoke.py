import os
import socket
import subprocess
import unittest
from copy import deepcopy
from pathlib import Path
from types import SimpleNamespace
from urllib.parse import urlsplit

from verify_spoke import secret_roundtrip, verify_control_plane, verify_private_dns


class DeploymentGuardTests(unittest.TestCase):
    def test_live_driver_refuses_without_explicit_approval(self):
        environment = dict(os.environ)
        environment.pop("ALLOW_LIVE_AZURE_TEST", None)
        result = subprocess.run(
            ["bash", str(Path(__file__).with_name("run.sh"))],
            env=environment, capture_output=True, text=True, timeout=10, check=False,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Refusing deployment", result.stderr)


class ControlPlaneTests(unittest.TestCase):
    def setUp(self):
        base = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test/providers/"
        self.vault = base + "Microsoft.KeyVault/vaults/test"
        self.spoke = base + "Microsoft.Network/virtualNetworks/spoke"
        self.hub = base + "Microsoft.Network/virtualNetworks/hub"
        self.subnet = self.spoke + "/subnets/private-endpoints"
        self.nsg = base + "Microsoft.Network/networkSecurityGroups/test"
        self.route = base + "Microsoft.Network/routeTables/test"
        self.endpoint = base + "Microsoft.Network/privateEndpoints/test"
        self.zone = base + "Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        self.law = base + "Microsoft.OperationalInsights/workspaces/test"
        self.insights = base + "Microsoft.Insights/components/test"
        self.alert = base + "Microsoft.Insights/metricAlerts/test"
        self.group = base + "Microsoft.Insights/actionGroups/test"
        self.budget = "/subscriptions/11111111-1111-1111-1111-111111111111/providers/Microsoft.Consumption/budgets/test"
        self.principal = "22222222-2222-2222-2222-222222222222"
        self.contract = {
            "contract_version": "1.0.0",
            "key_vault": {"id": self.vault, "private_endpoint_id": self.endpoint},
            "subnet_ids": {"private_endpoints": self.subnet},
            "spoke_virtual_network_id": self.spoke,
            "attachment_contract": {"hub_virtual_network_id": self.hub, "key_vault_private_dns_zone_id": self.zone},
            "security_baseline": {"egress_next_hop_ip": "10.250.0.4"},
            "diagnostic_ownership": {"workspace_id": self.law},
            "workload_identity": {"principal_id": self.principal},
            "environment_profile": {"telemetry_sampling_percentage": 20, "alert_severity": 3},
            "application_services": {"application_insights_id": self.insights, "failed_requests_alert_id": self.alert, "action_group_ids": [self.group],
                                     "budget_id": self.budget, "budget_amount": 100, "storage": {}},
        }
        self.resources = {
            self.vault: {"properties": {"enableRbacAuthorization": True, "publicNetworkAccess": "Disabled", "enablePurgeProtection": True, "softDeleteRetentionInDays": 90, "networkAcls": {"defaultAction": "Deny", "bypass": "None"}}},
            self.subnet: {"properties": {"defaultOutboundAccess": False, "privateEndpointNetworkPolicies": "Enabled", "networkSecurityGroup": {"id": self.nsg}, "routeTable": {"id": self.route}, "addressPrefixes": ["10.251.1.0/27"]}},
            self.nsg: {"properties": {"securityRules": [{"properties": {"direction": direction, "access": "Deny", "priority": 4096}} for direction in ["Inbound", "Outbound"]]}},
            self.route: {"properties": {"disableBgpRoutePropagation": True, "routes": [{"properties": {"addressPrefix": "0.0.0.0/0", "nextHopType": "VirtualAppliance", "nextHopIpAddress": "10.250.0.4"}}]}},
            self.endpoint: {"properties": {"subnet": {"id": self.subnet}, "privateLinkServiceConnections": [{"properties": {"privateLinkServiceId": self.vault, "groupIds": ["vault"], "privateLinkServiceConnectionState": {"status": "Approved"}}}]}},
            self.endpoint + "/privateDnsZoneGroups/default": {"properties": {"privateDnsZoneConfigs": [{"properties": {"privateDnsZoneId": self.zone}}]}},
            self.zone + "/virtualNetworkLinks": {"value": [{"properties": {"virtualNetwork": {"id": self.spoke}, "registrationEnabled": False}}]},
            self.vault + "/providers/Microsoft.Insights/diagnosticSettings": {"value": [{"properties": {"workspaceId": self.law, "logs": [{"category": "AuditEvent", "enabled": True}]}}]},
            self.insights: {"properties": {"DisableLocalAuth": True, "WorkspaceResourceId": self.law, "SamplingPercentage": 20}},
            self.alert: {"properties": {"enabled": True, "severity": 3, "actions": [{"actionGroupId": self.group}]}},
            self.budget: {"properties": {"amount": 100, "notifications": {str(index): {"enabled": True, "threshold": threshold, "thresholdType": kind, "contactGroups": [self.group]}
                                                                       for index, (threshold, kind) in enumerate([(80, "Actual"), (100, "Actual"), (100, "Forecasted")])}}},
        }
        for local, remote in [(self.spoke, self.hub), (self.hub, self.spoke)]:
            self.resources[local + "/virtualNetworkPeerings"] = {"value": [{"properties": {"remoteVirtualNetwork": {"id": remote}, "peeringState": "Connected", "allowForwardedTraffic": True}}]}

    def azure(self, *arguments):
        if arguments[0] == "role":
            return [{"scope": self.vault, "principalId": self.principal, "roleDefinitionName": "Key Vault Secrets User"}]
        return deepcopy(self.resources[urlsplit(arguments[arguments.index("--url") + 1]).path])

    def test_complete_observed_baseline_passes(self):
        self.assertEqual(verify_control_plane(self.contract, self.azure), ["10.251.1.0/27"])

    def test_phase_one_without_held_services_passes(self):
        services = self.contract["application_services"]
        for key in ("application_insights_id", "failed_requests_alert_id", "budget_id"):
            services[key] = None
        for resource_id in (self.insights, self.alert, self.budget):
            del self.resources[resource_id]
        verify_control_plane(self.contract, self.azure)

    def test_missing_specific_inspection_route_fails(self):
        self.contract["security_baseline"]["inspection_address_prefixes"] = ["10.250.0.0/24"]
        with self.assertRaisesRegex(AssertionError, "10.250.0.0/24"):
            verify_control_plane(self.contract, self.azure)

    def test_learned_gateway_bypass_fails(self):
        self.resources[self.route]["properties"]["disableBgpRoutePropagation"] = False
        with self.assertRaisesRegex(AssertionError, "BGP bypass"):
            verify_control_plane(self.contract, self.azure)

    def test_public_vault_fails(self):
        self.resources[self.vault]["properties"]["publicNetworkAccess"] = "Enabled"
        with self.assertRaisesRegex(AssertionError, "public access"):
            verify_control_plane(self.contract, self.azure)

    def test_missing_nsg_association_fails(self):
        del self.resources[self.subnet]["properties"]["networkSecurityGroup"]
        with self.assertRaisesRegex(AssertionError, "association"):
            verify_control_plane(self.contract, self.azure)

    def test_unconnected_peering_fails(self):
        self.resources[self.hub + "/virtualNetworkPeerings"]["value"][0]["properties"]["peeringState"] = "Initiated"
        with self.assertRaisesRegex(AssertionError, "peering"):
            verify_control_plane(self.contract, self.azure)

    def test_duplicate_diagnostic_setting_fails(self):
        values = self.resources[self.vault + "/providers/Microsoft.Insights/diagnosticSettings"]["value"]
        values.append(deepcopy(values[0]))
        with self.assertRaisesRegex(AssertionError, "duplicate"):
            verify_control_plane(self.contract, self.azure)

    def test_key_authenticated_telemetry_fails(self):
        self.resources[self.insights]["properties"]["DisableLocalAuth"] = False
        with self.assertRaisesRegex(AssertionError, "authentication"):
            verify_control_plane(self.contract, self.azure)

    def test_alert_without_destinations_fails(self):
        self.resources[self.alert]["properties"]["actions"] = []
        with self.assertRaisesRegex(AssertionError, "destinations"):
            verify_control_plane(self.contract, self.azure)

    def test_missing_forecast_budget_notification_fails(self):
        del self.resources[self.budget]["properties"]["notifications"]["2"]
        with self.assertRaisesRegex(AssertionError, "Budget notification"):
            verify_control_plane(self.contract, self.azure)

    def add_storage(self):
        account = self.spoke.split("/providers/")[0] + "/providers/Microsoft.Storage/storageAccounts/workload"
        endpoint = self.endpoint + "-blob"
        zone = self.zone.rsplit("/", 1)[0] + "/privatelink.blob.core.windows.net"
        self.contract["attachment_contract"]["storage_blob_private_dns_zone_id"] = zone
        self.contract["application_services"]["storage"] = {"data": {"id": account, "private_endpoint_id": endpoint, "replication_type": "LRS", "delete_retention_days": 7}}
        self.resources[account] = {"sku": {"name": "Standard_LRS"}, "properties": {"publicNetworkAccess": "Disabled", "allowSharedKeyAccess": False, "minimumTlsVersion": "TLS1_2", "supportsHttpsTrafficOnly": True}}
        self.resources[account + "/blobServices/default"] = {"properties": {"isVersioningEnabled": True, "deleteRetentionPolicy": {"enabled": True, "days": 7}, "containerDeleteRetentionPolicy": {"enabled": True, "days": 7}}}
        self.resources[endpoint] = {"properties": {"subnet": {"id": self.subnet}, "privateLinkServiceConnections": [{"properties": {"privateLinkServiceId": account, "groupIds": ["blob"], "privateLinkServiceConnectionState": {"status": "Approved"}}}]}}
        self.resources[endpoint + "/privateDnsZoneGroups/default"] = {"properties": {"privateDnsZoneConfigs": [{"properties": {"privateDnsZoneId": zone}}]}}
        self.resources[zone + "/virtualNetworkLinks"] = {"value": [{"properties": {"virtualNetwork": {"id": self.spoke}, "registrationEnabled": False}}]}
        self.resources[account + "/blobServices/default/providers/Microsoft.Insights/diagnosticSettings"] = {"value": [{"properties": {"workspaceId": self.law, "logs": [{"category": category, "enabled": True} for category in ["StorageRead", "StorageWrite", "StorageDelete"]]}}]}
        return account

    def test_observed_private_storage_passes(self):
        self.add_storage()
        verify_control_plane(self.contract, self.azure)

    def test_public_storage_fails(self):
        account = self.add_storage()
        self.resources[account]["properties"]["publicNetworkAccess"] = "Enabled"
        with self.assertRaisesRegex(AssertionError, "private and keyless"):
            verify_control_plane(self.contract, self.azure)

    def test_missing_blob_child_diagnostics_fails(self):
        account = self.add_storage()
        self.resources[account + "/blobServices/default/providers/Microsoft.Insights/diagnosticSettings"]["value"] = []
        with self.assertRaisesRegex(AssertionError, "Blob logs"):
            verify_control_plane(self.contract, self.azure)


class PrivateAccessTests(unittest.TestCase):
    def test_private_dns_requires_endpoint_subnet(self):
        def resolve(*args):
            return [(socket.AF_INET, socket.SOCK_STREAM, 6, "", ("10.200.1.4", 443))]
        verify_private_dns("https://test.vault.azure.net/", ["10.200.1.0/27"], resolve)

    def test_public_resolution_is_rejected(self):
        def resolve(*args):
            return [(socket.AF_INET, socket.SOCK_STREAM, 6, "", ("20.0.0.1", 443))]
        with self.assertRaises(AssertionError):
            verify_private_dns("https://test.vault.azure.net/", ["10.200.1.0/27"], resolve)

    def test_other_private_subnet_is_rejected(self):
        def resolve(*args):
            return [(socket.AF_INET, socket.SOCK_STREAM, 6, "", ("10.201.1.4", 443))]
        with self.assertRaises(AssertionError):
            verify_private_dns("https://test.vault.azure.net/", ["10.200.1.0/27"], resolve)

    def test_non_azure_vault_uri_is_rejected(self):
        with self.assertRaises(AssertionError):
            verify_private_dns("https://example.com/", ["10.200.1.0/27"])

    def test_secret_roundtrip_uses_reader_and_deletes_probe(self):
        values = {}
        deleted = []
        writer = SimpleNamespace(
            set_secret=lambda name, value: values.update({name: value}),
            begin_delete_secret=lambda name: SimpleNamespace(wait=lambda: deleted.append(name)),
        )
        reader = SimpleNamespace(get_secret=lambda name: SimpleNamespace(value=values[name]))
        secret_roundtrip(writer, reader)
        self.assertEqual(list(values), deleted)
        self.assertTrue(deleted[0].startswith("integration-probe-"))

    def test_failed_reader_still_deletes_probe(self):
        deleted = []
        writer = SimpleNamespace(set_secret=lambda *args: None, begin_delete_secret=lambda name: SimpleNamespace(wait=lambda: deleted.append(name)))
        reader = SimpleNamespace(get_secret=lambda name: SimpleNamespace(value="incorrect"))
        with self.assertRaises(AssertionError):
            secret_roundtrip(writer, reader)
        self.assertEqual(len(deleted), 1)


if __name__ == "__main__":
    unittest.main()
