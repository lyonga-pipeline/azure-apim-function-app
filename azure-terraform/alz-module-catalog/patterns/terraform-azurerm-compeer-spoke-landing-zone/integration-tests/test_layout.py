import re
import unittest
from pathlib import Path


BLUEPRINT = Path(__file__).resolve().parents[1]


class BlueprintLayoutTests(unittest.TestCase):
    def test_locals_are_in_one_block_in_locals_file(self):
        locations = [
            path.name
            for path in BLUEPRINT.glob("*.tf")
            for _ in re.finditer(r"^locals\s*\{", path.read_text(), re.MULTILINE)
        ]
        self.assertEqual(locations, ["locals.tf"])

    def test_provisioning_is_in_main_and_only_contracts_are_separate(self):
        for path in BLUEPRINT.glob("*.tf"):
            for kind, label in re.findall(r'^\s*(module|resource)\s+"([^"]+)"', path.read_text(), re.MULTILINE):
                with self.subTest(file=path.name, kind=kind, label=label):
                    self.assertTrue(
                        path.name == "main.tf"
                        or (path.name == "contracts.tf" and kind == "resource" and label == "terraform_data")
                    )

    def test_inputs_stay_in_variables_file(self):
        for path in BLUEPRINT.glob("*.tf"):
            if re.search(r"^variable\s+", path.read_text(), re.MULTILINE):
                self.assertEqual(path.name, "variables.tf")

    def test_blueprint_cannot_create_peerings_or_vnet_zone_links(self):
        source = "\n".join(path.read_text() for path in BLUEPRINT.glob("*.tf"))
        self.assertNotIn('module "attachment_naming"', source)
        self.assertNotIn("private_dns_link_vnets", source)
        self.assertNotIn('source = "../terraform-azurerm-compeer-hub-spoke-peering"', source)
        self.assertNotRegex(source, r'source\s*=\s*"[^"]*(?:vnet-peering|private-dns-vnet-link)"')
        self.assertNotRegex(source, r'resource\s+"azurerm_(?:virtual_network_peering|private_dns_zone_virtual_network_link)"')
        self.assertNotIn("azurerm.connectivity", source)


if __name__ == "__main__":
    unittest.main()
