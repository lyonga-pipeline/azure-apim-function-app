"""Read-only acceptance: python3 check_live.py <terraform-output-json-file>.

The input is produced by `terraform output -json attachments` in the correct
attachment state. Requires an already authenticated Azure CLI read identity.
DNS queries and representative inspected/blocked application flows remain separate.
"""

import json
import re
import subprocess
import sys
from pathlib import Path


def read_resource(resource_id, api_version):
    if not re.fullmatch(r"/subscriptions/[0-9a-fA-F-]{36}/resourceGroups/[^/?#]+/providers/Microsoft.Network/(virtualNetworks/[^/?#]+/virtualNetworkPeerings/[^/?#]+|privateDnsZones/[^/?#]+/virtualNetworkLinks/[^/?#]+)", resource_id, re.IGNORECASE):
        raise ValueError("Expected a peering or DNS VNet-link resource ID, not a parent resource")
    response = subprocess.run(
        ["az", "rest", "--method", "get", "--url", f"https://management.azure.com{resource_id}?api-version={api_version}", "--output", "json"],
        check=True, text=True, capture_output=True,
    )
    return json.loads(response.stdout)["properties"]


def check(attachments, read=read_resource):
    if not attachments:
        raise ValueError("Empty inventory is not connectivity acceptance")
    for key, attachment in attachments.items():
        for direction, remote in [("hub_to_spoke", attachment["spoke_virtual_network_id"]),
                                  ("spoke_to_hub", attachment["hub_virtual_network_id"])]:
            properties = read(attachment[direction + "_id"], "2024-05-01")
            if (properties.get("peeringState") != "Connected" or properties.get("provisioningState") != "Succeeded"
                    or properties["remoteVirtualNetwork"]["id"].lower() != remote.lower()):
                raise ValueError(f"{key}/{direction} is not Connected/Succeeded to its approved remote VNet")
        for link_id in attachment["private_dns_link_ids"].values():
            properties = read(link_id, "2020-06-01")
            if (properties.get("provisioningState") != "Succeeded" or properties.get("registrationEnabled") is not False
                    or properties["virtualNetwork"]["id"].lower() != attachment["spoke_virtual_network_id"].lower()):
                raise ValueError(f"{key}: DNS link is not provisioned against the approved spoke with registration off")
        print(f"{key}: reciprocal peering and approved DNS link control-plane checks passed")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    check(json.loads(Path(sys.argv[1]).read_text()))
