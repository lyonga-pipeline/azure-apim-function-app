import re
import unittest
from pathlib import Path


CATALOG = Path(__file__).resolve().parents[3]
VAULT = CATALOG / "patterns/terraform-azurerm-compeer-workload-key-vault"


class VaultLayoutTests(unittest.TestCase):
    def test_example_inputs_track_the_parent_schema_and_validations(self):
        parent = (VAULT / "variables.tf").read_text().strip()
        example = (VAULT / "examples/variables.tf").read_text().split('variable "subscription_id"')[0].strip()
        self.assertEqual(parent, example)
        inputs = re.findall(r'^variable "([^"]+)"', parent, re.MULTILINE)
        caller = (VAULT / "examples/main.tf").read_text()
        for name in inputs:
            with self.subTest(input=name):
                self.assertRegex(caller, r"(?m)^\s*" + name + r"\s*=\s*var\." + name + r"\s*$")

    def test_baseline_cannot_enable_legacy_authorization_or_weaken_recovery(self):
        source = (VAULT / "main.tf").read_text()
        for setting in [r"rbac_authorization_enabled\s*=\s*true", r"purge_protection_enabled\s*=\s*true", r"soft_delete_retention_days\s*=\s*90", r'default_action\s*=\s*"Deny"']:
            self.assertRegex(source, setting)
        self.assertNotIn("access_policies", (VAULT / "variables.tf").read_text())
        self.assertNotRegex(source, r'azurerm_(?:management_lock|consumption_budget|key_vault_secret|key_vault_certificate)')

    def test_existing_endpoint_has_an_explicit_address_move(self):
        moves = (VAULT / "moved.tf").read_text()
        self.assertRegex(moves, r'from\s*=\s*module\.private_endpoint\s+to\s*=\s*module\.private_endpoint\["default"\]')
        locals_source = (VAULT / "locals.tf").read_text()
        self.assertNotIn("var.private_endpoint_subnet_id != null", locals_source)

    def test_variants_are_complete_alternatives_not_automatic_deployments(self):
        variants = list((VAULT / "examples/variants").glob("*.tfvars"))
        self.assertEqual(len(variants), 4)
        for variant in variants:
            with self.subTest(variant=variant.name):
                self.assertNotRegex(variant.read_text(), r"(?m)^(?:enabled|deployment_approved)\s*=\s*true")
        baseline = (VAULT / "examples/baseline.tfvars").read_text()
        self.assertRegex(baseline, r"(?m)^enabled\s*=\s*false")
        self.assertRegex(baseline, r"(?m)^deployment_approved\s*=\s*false")


if __name__ == "__main__":
    unittest.main()
