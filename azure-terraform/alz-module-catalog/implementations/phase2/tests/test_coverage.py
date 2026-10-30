"""PHASE2 NEW: workbook completeness and backwards-compatible ownership structure."""
import json
import os
import posixpath
import re
from pathlib import Path
import unittest
from xml.etree import ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT.parents[1]
MANIFEST = json.loads((ROOT / "coverage.json").read_text())
IMPLEMENTATIONS = json.loads((ROOT / "implementation-map.json").read_text())
NS = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}


def workbook_rows(source, sheet_name):
    """Resolve actual sheet names/relationships; tab reordering must not change coverage."""
    with ZipFile(source) as archive:
        strings = ["".join(node.itertext()) for node in ET.fromstring(archive.read("xl/sharedStrings.xml"))]
        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        relationships = {node.get("Id"): node.get("Target") for node in ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))}
        sheet = next(node for node in workbook.findall("s:sheets/s:sheet", NS) if node.get("name") == sheet_name)
        target = relationships[sheet.get("{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id")]
        path = target.lstrip("/") if target.startswith("/") else posixpath.normpath(posixpath.join("xl", target))
        for row in ET.fromstring(archive.read(path)).findall("s:sheetData/s:row", NS):
            values = {}
            for cell in row.findall("s:c", NS):
                value = cell.find("s:v", NS)
                text = "" if value is None else value.text or ""
                if cell.get("t") == "s" and text:
                    text = strings[int(text)]
                elif cell.get("t") == "inlineStr":
                    text = "".join(cell.find("s:is", NS).itertext())
                values["".join(filter(str.isalpha, cell.attrib["r"]))] = text
            yield int(row.get("r")), values

class CoverageTests(unittest.TestCase):
    def test_all_49_activities_have_real_artifacts(self):
        rows = MANIFEST["activities"]
        self.assertEqual(len(rows), 49)
        self.assertEqual(len({row["sequence"] for row in rows}), 49)
        self.assertEqual(sum(row["in_scope"] for row in rows), 45)
        self.assertEqual(len(MANIFEST["supplemental_components"]), 4)
        for row in rows + MANIFEST["supplemental_components"]:
            with self.subTest(step=row.get("sequence", row.get("component"))):
                path = CATALOG / row["path"]
                self.assertTrue(path.is_file(), path)
                self.assertTrue(row["notes"].strip())
                if path.suffix == ".tf":
                    self.assertIn("PHASE2", path.read_text())
                for implementation in row.get("implementation_paths", []):
                    self.assertTrue((CATALOG / implementation).is_file(), implementation)

    def test_workbook_matches_when_source_is_supplied(self):
        source = os.environ.get("PHASE2_WORKBOOK")
        if not source:
            self.skipTest("Set PHASE2_WORKBOOK to compare with the original v5 workbook.")
        actual = {}
        deferred = set()
        for number, values in workbook_rows(source, MANIFEST["sheet"]):
            sequence = values.get("A", "")
            if sequence and sequence[0].isdigit():
                key = f"{float(sequence):.1f}"
                actual[key] = values.get("B", "")
                if "phase 3" in " ".join(values.values()).lower():
                    deferred.add(key)
                self.assertEqual(number, next(row["row"] for row in MANIFEST["activities"] if row["sequence"] == key))
        self.assertEqual(actual, {row["sequence"]: row["activity"] for row in MANIFEST["activities"]})
        self.assertEqual(deferred, {row["sequence"] for row in MANIFEST["activities"] if not row["in_scope"]})

    def test_component_list_phase2_is_not_lost_between_sheets(self):
        source = os.environ.get("PHASE2_WORKBOOK")
        if not source:
            self.skipTest("Set PHASE2_WORKBOOK for the independent Component List cross-check.")
        components = {}
        for number, values in workbook_rows(source, "Component List"):
            if values.get("G", "").strip() == "Phase 2":
                components[values.get("A", "")] = number
        order_ids = set()
        for row in MANIFEST["activities"]:
            order_ids.update(re.findall(r"[A-Z]+-\d+", row["components"]))
        extra = {row["component"]: row["row"] for row in MANIFEST["supplemental_components"]}
        self.assertEqual({key: number for key, number in components.items() if key not in order_ids}, extra)
        self.assertTrue(set(components).issubset(order_ids | set(extra)))

    def test_new_roots_do_not_use_shared_environment_adapter(self):
        for item in IMPLEMENTATIONS["new_roots"]:
            path = CATALOG / item["path"] / "main.tf"
            with self.subTest(root=path.parent.name):
                text = path.read_text()
                self.assertIn('../../../../patterns/', text)
                self.assertNotIn('/shared', text)

    def test_explicit_holds_and_no_vending_or_management_locks(self):
        holds = (ROOT / "ON-HOLD.md").read_text()
        for item in ("1.4", "4.5", "4.6", "9.4"):
            self.assertIn(item, holds)
        for item in IMPLEMENTATIONS["new_roots"]:
            path = CATALOG / item["path"] / "main.tf"
            text = path.read_text()
            self.assertNotIn('resource "azurerm_management_lock"', text)
            self.assertNotIn('vending_enabled = true', text)
        for root in ("workload-sandbox", "workload-external-apps-prod"):
            self.assertRegex((CATALOG / "implementations/workload-lz/workspaces" / root / "main.tf").read_text(), r"manage_hub_attachment\s*=\s*false")

    def test_phase3_hcp_resources_are_not_in_the_delivery(self):
        text = "\n".join(path.read_text() for path in (CATALOG / "patterns/terraform-azurerm-compeer-hcp-governance").glob("*.tf"))
        for resource in ("tfe_workspace", "tfe_team", "tfe_team_access", "tfe_workspace_variable_set"):
            self.assertNotRegex(text, rf'resource\s+"{resource}"\s+')
        for row in MANIFEST["activities"]:
            if not row["in_scope"]:
                self.assertEqual(row["status"], "EXCLUDED_PHASE3")
                self.assertEqual(row["path"], "implementations/phase2/ON-HOLD.md")

    def test_new_provider_context_is_explicit(self):
        for item in IMPLEMENTATIONS["new_roots"]:
            path = CATALOG / item["path"] / "terraform.tf"
            text = path.read_text()
            if 'provider "azurerm"' in text:
                self.assertIn("subscription_id", text)
                self.assertIn("resource_provider_registrations", text)

    def test_existing_owners_have_visible_additive_phase2_sections(self):
        expected = {"platform-management": "management", "platform-connectivity": "connectivity", "platform-directory-services": "directory_services", "platform-cloudflare-connectors": "cloudflare_connectors", "platform-policy": "policy"}
        for item in IMPLEMENTATIONS["existing_roots"]:
            directory = CATALOG / item["path"]
            with self.subTest(root=directory.name):
                main = (directory / "main.tf").read_text()
                self.assertIn("PHASE 2 CHANGES", main)
                self.assertIn(f'module "{expected[directory.name]}"', main)
                self.assertNotRegex(main, r'(?m)^\s*(moved|removed)\s*\{')
                for name in ("phase2_variables.tf", "phase2_outputs.tf", item["example"]):
                    self.assertTrue((directory / name).is_file())
                    self.assertIn("PHASE 2", (directory / name).read_text())

    def test_no_deployable_phase_based_roots_remain(self):
        self.assertFalse(any((ROOT / "workspaces").rglob("*.tf")))
        self.assertEqual(len(IMPLEMENTATIONS["new_roots"]), 8)
        self.assertEqual(len(IMPLEMENTATIONS["existing_roots"]), 5)
        all_paths = [item["path"] for item in IMPLEMENTATIONS["new_roots"] + IMPLEMENTATIONS["existing_roots"]]
        self.assertEqual(len(all_paths), len(set(all_paths)))

    def test_policy_and_finops_have_disjoint_interfaces(self):
        platform = CATALOG / "implementations/platform-lz/workspaces"
        policy = (platform / "platform-policy/phase2_variables.tf").read_text()
        finops = (platform / "platform-finops/variables.tf").read_text()
        for name in ("budgets", "cost_exports", "cost_anomalies"):
            self.assertNotIn(f'variable "phase2_{name}"', policy)
            self.assertIn(f'variable "{name}"', finops)
        for name in ("audit_initiatives", "exemptions", "sandbox_scope"):
            self.assertNotIn(f'variable "{name}"', finops)
            self.assertIn(f'variable "phase2_{name}"', policy)

    def test_vm_agents_accept_only_owner_keys_not_arbitrary_vm_ids(self):
        platform = CATALOG / "implementations/platform-lz/workspaces"
        for name in ("platform-directory-services", "platform-cloudflare-connectors", "platform-identity-external"):
            variables = (platform / name / "phase2_variables.tf").read_text()
            self.assertNotIn("virtual_machine_id", variables)
            self.assertIn("phase2_agent_ownership_confirmed", variables)
            self.assertIn("PHASE 2 CHANGES", (platform / name / "main.tf").read_text())

    def test_new_composition_reads_public_outputs_only(self):
        for name in ("platform-connectivity", "platform-directory-services", "platform-cloudflare-connectors"):
            path = CATALOG / "implementations/platform-lz/workspaces" / name / "main.tf"
            extension = path.read_text().split("# PHASE 2 CHANGES", 1)[1]
            self.assertIn(".nonsensitive_values.log_analytics_workspace_id", extension)
            self.assertNotIn(".values", extension)

if __name__ == "__main__":
    unittest.main()
