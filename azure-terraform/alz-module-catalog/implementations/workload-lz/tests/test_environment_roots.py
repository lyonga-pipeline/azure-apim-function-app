import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


WORKLOAD = Path(__file__).resolve().parents[1]
ROOTS = [WORKLOAD / "workspaces" / f"workload-internal-apps-{env}" for env in ("prod", "nonprod")]


class EnvironmentRootTests(unittest.TestCase):
    def test_shared_adapter_is_removed_and_regression_roots_exist(self):
        self.assertFalse((WORKLOAD / "shared").exists())
        script = (WORKLOAD / "test.sh").read_text()
        roots = re.findall(r"^  (implementations/\S+)$", script, re.MULTILINE)
        self.assertTrue(roots)
        for root in roots:
            with self.subTest(root=root):
                self.assertTrue((WORKLOAD.parents[1] / root).is_dir())

    def test_each_root_calls_one_immutable_blueprint_directly(self):
        for root in ROOTS:
            with self.subTest(root=root.name):
                source = "\n".join(path.read_text() for path in root.glob("*.tf"))
                self.assertEqual(re.findall(r'^module "([^"]+)"', source, re.MULTILINE), ["blueprint"])
                self.assertNotIn('source = "../../shared"', source)
                if 'source = "https://codeload.github.com/' in source:
                    self.assertRegex(
                        source,
                        r'source\s*=\s*"https://codeload\.github\.com/lyonga-pipeline/azure-apim-function-app/zip/([0-9a-f]{40})//azure-apim-function-app-\1/azure-terraform/alz-module-catalog/patterns/terraform-azurerm-compeer-spoke-landing-zone\?archive=zip"',
                    )
                else:
                    self.assertRegex(source, r'source\s*=\s*"app\.terraform\.io/Compeer-Financial-Services/[a-zA-Z0-9_-]+/azurerm"')
                    self.assertRegex(source, r'version\s*=\s*"\d+\.\d+\.\d+"')
                self.assertIn('count  = local.enabled ? 1 : 0', source)
                self.assertIn('environment     = "prod"' if root.name.endswith("-prod") else 'environment     = var.environment', source)

    def test_roots_preserve_public_contract_and_budget_guard(self):
        for root in ROOTS:
            with self.subTest(root=root.name):
                source = (root / "main.tf").read_text()
                self.assertEqual(source.count(".nonsensitive_values"), 0)
                self.assertEqual((root / "locals.tf").read_text().count(".nonsensitive_values"), 3)
                self.assertNotIn("terraform_remote_state", source)
                self.assertIn("!can(var.spoke.operations.budget)", (root / "variables.tf").read_text())
                self.assertIn("created_on = try(formatdate", source)
                self.assertIn("local.spoke_contract", (root / "outputs.tf").read_text())
                self.assertIn("enabled                 = false", (root / "terraform.tfvars").read_text())

    def test_environment_roots_do_not_copy_azure_resource_implementation(self):
        for root in ROOTS:
            with self.subTest(root=root.name):
                source = "\n".join(path.read_text() for path in root.glob("*.tf"))
                self.assertNotRegex(source, r'resource\s+"azurerm_')
                self.assertNotIn("azurerm.connectivity", source)
                self.assertIn('data "tfe_outputs" "governance"', source)


class AdapterMigrationTests(unittest.TestCase):
    """Apply only local built-ins/time, then test the real roots' move declarations."""

    def terraform(self, root, *args):
        result = subprocess.run(
            ["terraform", f"-chdir={root}", *args],
            text=True,
            capture_output=True,
            timeout=180,
            env={**os.environ, "TF_IN_AUTOMATION": "true"},
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def verify_migration(self, root):
        with tempfile.TemporaryDirectory(prefix="spoke-root-migration-") as directory:
            fixture = Path(directory)
            (fixture / "adapter").mkdir()
            (fixture / "blueprint" / "vault").mkdir(parents=True)
            # Nested map/count addresses exercise moving the whole blueprint subtree.
            (fixture / "blueprint" / "main.tf").write_text('''resource "terraform_data" "subnet" {
  for_each = toset(["application", "private_endpoints"])
  input    = each.key
}
module "vault" {
  source = "./vault"
  count  = 1
}
''')
            (fixture / "blueprint" / "vault" / "main.tf").write_text('''resource "terraform_data" "vault" {
  input = "unchanged-vault"
}
''')
            adapter = '''terraform {
  required_providers {
    time = { source = "hashicorp/time", version = ">= 0.9.0, < 1.0.0" }
  }
}
resource "time_static" "deployment_created" {
  count = 1
}
resource "terraform_data" "deployment_contract" {
  count = 1
}
module "blueprint" {
  source = "../blueprint"
  count  = 1
}
output "created_on" {
  value = time_static.deployment_created[0].rfc3339
}
'''
            (fixture / "adapter" / "main.tf").write_text(adapter)
            (fixture / "main.tf").write_text('''module "deployment" {
  source = "./adapter"
}
output "created_on" {
  value = module.deployment.created_on
}
''')
            self.terraform(fixture, "init", "-backend=false", "-input=false", "-no-color")
            self.terraform(fixture, "apply", "-auto-approve", "-input=false", "-no-color")
            before = json.loads(self.terraform(fixture, "show", "-json"))

            (fixture / "main.tf").write_text(adapter.replace('source = "../blueprint"', 'source = "./blueprint"'))
            shutil.copyfile(root / "moved.tf", fixture / "moved.tf")
            self.terraform(fixture, "init", "-backend=false", "-input=false", "-no-color")
            self.terraform(fixture, "plan", "-refresh=false", "-input=false", "-no-color", "-out=migration.plan")
            plan = json.loads(self.terraform(fixture, "show", "-json", "migration.plan"))
            changes = plan["resource_changes"]
            self.assertEqual(len(changes), 5)
            for change in changes:
                with self.subTest(address=change["address"]):
                    self.assertEqual(change["change"]["actions"], ["no-op"])
                    self.assertEqual(change["previous_address"], "module.deployment." + change["address"])
                    self.assertEqual(change["change"]["before"]["id"], change["change"]["after"]["id"])
            self.assertEqual(
                plan["planned_values"]["outputs"]["created_on"]["value"],
                before["values"]["outputs"]["created_on"]["value"],
            )
            self.terraform(fixture, "apply", "-input=false", "-no-color", "migration.plan")
            self.terraform(fixture, "plan", "-refresh=false", "-input=false", "-no-color", "-detailed-exitcode")

    def test_production_moves_preserve_resources_and_creation_timestamp(self):
        self.verify_migration(ROOTS[0])

    def test_nonproduction_moves_preserve_resources_and_creation_timestamp(self):
        self.verify_migration(ROOTS[1])

    def test_vault_keyed_endpoint_and_indexed_diagnostics_preserve_ids(self):
        with tempfile.TemporaryDirectory(prefix="vault-endpoint-migration-") as directory:
            fixture = Path(directory)
            (fixture / "endpoint").mkdir()
            (fixture / "endpoint" / "main.tf").write_text('resource "terraform_data" "endpoint" { input = "unchanged" }\n')
            old = '''module "private_endpoint" {
  source = "./endpoint"
}
module "diagnostics" {
  source = "./endpoint"
}
'''
            (fixture / "main.tf").write_text(old)
            self.terraform(fixture, "init", "-backend=false", "-input=false", "-no-color")
            self.terraform(fixture, "apply", "-auto-approve", "-input=false", "-no-color")
            new = old.replace('module "private_endpoint" {', 'module "private_endpoint" {\n  for_each = { default = true }').replace('module "diagnostics" {', 'module "diagnostics" {\n  count = 1')
            (fixture / "main.tf").write_text(new)
            catalog = WORKLOAD.parents[1]
            shutil.copyfile(catalog / "patterns/terraform-azurerm-compeer-workload-key-vault/moved.tf", fixture / "moved.tf")
            self.terraform(fixture, "init", "-backend=false", "-input=false", "-no-color")
            self.terraform(fixture, "plan", "-refresh=false", "-input=false", "-no-color", "-out=migration.plan")
            plan = json.loads(self.terraform(fixture, "show", "-json", "migration.plan"))
            self.assertEqual(len(plan["resource_changes"]), 2)
            for change in plan["resource_changes"]:
                self.assertEqual(change["change"]["actions"], ["no-op"])
                self.assertEqual(change["change"]["before"]["id"], change["change"]["after"]["id"])
                self.assertIn("previous_address", change)
            self.terraform(fixture, "apply", "-input=false", "-no-color", "migration.plan")
            self.terraform(fixture, "plan", "-refresh=false", "-input=false", "-no-color", "-detailed-exitcode")


if __name__ == "__main__":
    unittest.main()
