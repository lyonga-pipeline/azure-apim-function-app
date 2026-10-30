import copy
import importlib.util
from pathlib import Path
import re
import unittest


HERE = Path(__file__).resolve().parents[1]
CATALOG = HERE.parents[2]


def load(name):
    spec = importlib.util.spec_from_file_location(name, HERE / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


gate = load("run_under_hub_gate")
live = load("check_live")


class FakeHCP:
    def __init__(self):
        self.responses = {
            "organizations/org/workspaces/prod": {"data": {"id": "ws-prod", "attributes": {
                "auto-apply": False, "working-directory": "prod"}, "relationships": {
                    "current-run": {"data": None},
                    "current-configuration-version": {"data": {"id": "cv-approved"}},
                }}},
            "organizations/org/workspaces/np1": {"data": {"id": "ws-np1", "attributes": {
                "auto-apply": False}, "relationships": {"current-run": {"data": None}}}},
            "configuration-versions/cv-approved": {"data": {"attributes": {"status": "uploaded", "speculative": False}}},
            "configuration-versions/cv-approved/ingress-attributes": {"data": {"attributes": {
                "commit-sha": "a" * 40, "branch": "main", "is-pull-request": False, "identifier": "approved/repo"}}},
            "runs": {"data": {"id": "run-new"}},
            "runs/run-new": {"data": {"attributes": {"status": "applied"}}},
        }
        self.posts = []

    def request(self, path, payload=None):
        if payload:
            self.posts.append((path, payload))
        return copy.deepcopy(self.responses[path])


class GateTests(unittest.TestCase):
    def setUp(self):
        self.client = FakeHCP()
        self.config = {"organization": "org", "vcs_identifier": "approved/repo", "workspaces": {"prod": "prod", "np1": "np1"}}

    def preflight(self):
        return gate.preflight(self.client, self.config, "prod", "cv-approved", "a" * 40)

    def test_exact_main_commit_and_root_are_required(self):
        self.assertEqual(self.preflight(), "ws-prod")
        self.client.responses["configuration-versions/cv-approved/ingress-attributes"]["data"]["attributes"]["commit-sha"] = "b" * 40
        with self.assertRaises(ValueError):
            self.preflight()

    def test_approved_platform_and_custom_workspaces_are_not_restricted_to_four_names(self):
        for name in ["platform-network-peering-shared", "platform-network-peering-perf"]:
            with self.subTest(name=name):
                config = copy.deepcopy(self.config)
                config["workspaces"][name] = name
                self.client.responses["organizations/org/workspaces/" + name] = copy.deepcopy(self.client.responses["organizations/org/workspaces/prod"])
                self.client.responses["organizations/org/workspaces/" + name]["data"]["attributes"]["working-directory"] = name
                self.assertEqual(gate.preflight(self.client, config, name, "cv-approved", "a" * 40), "ws-prod")

    def test_other_environment_active_run_blocks_new_mutations(self):
        self.client.responses["organizations/org/workspaces/np1"]["data"]["relationships"]["current-run"]["data"] = {"id": "run-active"}
        self.client.responses["runs/run-active"] = {"data": {"attributes": {"status": "applying"}}}
        with self.assertRaisesRegex(ValueError, "unfinished run"):
            self.preflight()
        self.assertEqual(self.client.posts, [])

    def test_autoapply_is_rejected_for_every_hub_writer(self):
        self.client.responses["organizations/org/workspaces/np1"]["data"]["attributes"]["auto-apply"] = True
        with self.assertRaisesRegex(ValueError, "auto-apply"):
            self.preflight()

    def test_wrong_working_directory_is_rejected(self):
        self.client.responses["organizations/org/workspaces/prod"]["data"]["attributes"]["working-directory"] = "np1"
        with self.assertRaisesRegex(ValueError, "working directory"):
            self.preflight()

    def test_feature_branch_and_unapproved_repository_are_rejected(self):
        ingress = self.client.responses["configuration-versions/cv-approved/ingress-attributes"]["data"]["attributes"]
        for field, value in [("branch", "feature"), ("identifier", "other/repo"), ("is-pull-request", True)]:
            with self.subTest(field=field):
                original = ingress[field]
                ingress[field] = value
                with self.assertRaises(ValueError):
                    self.preflight()
                ingress[field] = original

    def test_stale_configuration_is_rejected(self):
        self.client.responses["organizations/org/workspaces/prod"]["data"]["relationships"]["current-configuration-version"]["data"]["id"] = "cv-newer"
        with self.assertRaisesRegex(ValueError, "current reviewed"):
            self.preflight()

    def test_queue_never_autoapplies_or_destroys(self):
        self.assertEqual(gate.queue(self.client, "ws-prod", "cv-approved"), "run-new")
        attributes = self.client.posts[0][1]["data"]["attributes"]
        self.assertIs(attributes["auto-apply"], False)
        self.assertIs(attributes["is-destroy"], False)
        self.assertIs(attributes["refresh"], True)

    def test_failed_run_is_not_success(self):
        self.client.responses["runs/run-new"]["data"]["attributes"]["status"] = "errored"
        with self.assertRaises(RuntimeError):
            gate.wait(self.client, "run-new", 1)

    def test_timeout_does_not_forcecancel_or_apply(self):
        self.client.responses["runs/run-new"]["data"]["attributes"]["status"] = "applying"
        ticks = iter([0, 2])
        with self.assertRaisesRegex(RuntimeError, "remains active"):
            gate.wait(self.client, "run-new", 1, sleep=lambda _: None, monotonic=lambda: next(ticks))
        self.assertEqual(self.client.posts, [])


class LiveCheckTests(unittest.TestCase):
    def setUp(self):
        self.inventory = {"orders": {
            "hub_virtual_network_id": "hub", "spoke_virtual_network_id": "spoke", "hub_to_spoke_id": "forward",
            "spoke_to_hub_id": "reverse", "private_dns_link_ids": {"vault": "link"}}}
        self.properties = {
            "forward": {"peeringState": "Connected", "provisioningState": "Succeeded", "remoteVirtualNetwork": {"id": "spoke"}},
            "reverse": {"peeringState": "Connected", "provisioningState": "Succeeded", "remoteVirtualNetwork": {"id": "hub"}},
            "link": {"provisioningState": "Succeeded", "registrationEnabled": False, "virtualNetwork": {"id": "spoke"}},
        }

    def check(self):
        live.check(self.inventory, read=lambda resource_id, _: self.properties[resource_id])

    def test_reciprocal_connected_and_dns_pass(self):
        self.check()

    def test_initiated_half_is_not_acceptance(self):
        self.properties["reverse"]["peeringState"] = "Initiated"
        with self.assertRaisesRegex(ValueError, "Connected"):
            self.check()

    def test_dns_registration_or_wrong_vnet_is_rejected(self):
        self.properties["link"]["registrationEnabled"] = True
        with self.assertRaisesRegex(ValueError, "DNS link"):
            self.check()

    def test_empty_inventory_is_not_acceptance(self):
        with self.assertRaises(ValueError):
            live.check({})

    def test_parent_id_cannot_be_sent_to_live_checker(self):
        with self.assertRaises(ValueError):
            live.read_resource("/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub", "2024-05-01")


class OwnershipTests(unittest.TestCase):
    def test_generic_producer_is_output_only_and_does_not_transfer_ownership(self):
        producer = CATALOG / "patterns/terraform-azapi-compeer-network-attachments/producer/main.tf"
        self.assertNotRegex(producer.read_text(), r'\bresource\s+"')
        template = CATALOG / "implementations/platform-lz/templates/network-attachments"
        self.assertIn('environment = var.environment', (template / "main.tf").read_text())
        self.assertRegex((template / "terraform.tfvars").read_text(), r"enabled\s*= false")

    def test_batch_manages_only_peering_and_dns_children(self):
        pattern = CATALOG / "patterns/terraform-azapi-compeer-network-attachments"
        main = (pattern / "main.tf").read_text()
        self.assertEqual(re.findall(r'resource "([^"]+)" "([^"]+)"', main), [
            ("azapi_resource", "hub_to_spoke"), ("azapi_resource", "spoke_to_hub"), ("azapi_resource", "dns_link")])
        self.assertEqual(main.count('type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01"'), 2)
        self.assertNotIn('resource "azurerm_virtual_network"', main)
        self.assertNotIn('resource "azurerm_route"', main)
        self.assertNotIn("azurerm.", main)

    def test_environment_roots_have_fixed_boundaries_and_one_provider(self):
        roots = CATALOG / "implementations/platform-lz/workspaces"
        for env in ["nonprod", "prod"]:
            root = roots / ("platform-network-peering-" + env)
            self.assertIn(f'environment = "{env}"', (root / "main.tf").read_text())
            self.assertEqual((root / "providers.tf").read_text().count('provider "azapi"'), 1)
            self.assertNotIn("alias", (root / "providers.tf").read_text())
            self.assertRegex((root / "terraform.tfvars").read_text(), r"enabled\s*= false")
        self.assertIn('allowed_environments    = ["prod"]', (roots / "platform-network-peering-prod/main.tf").read_text())
        self.assertIn("allowed_environments    = var.allowed_environments", (roots / "platform-network-peering-nonprod/main.tf").read_text())
        for env in ["np1", "np2", "np3"]:
            self.assertFalse((roots / ("platform-network-peering-" + env) / "main.tf").exists())


if __name__ == "__main__":
    unittest.main()
