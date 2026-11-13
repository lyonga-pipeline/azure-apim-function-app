import unittest
from unittest.mock import patch

import tunnel_release as release


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.item = {"account_id": "a" * 32, "tunnel_id": "00000000-0000-4000-8000-000000000001",
                     "vault_uri": "https://test-vault.vault.azure.net", "secret_name": "np-token"}

    def test_inventory_accepts_references(self):
        release.validate_inventory([self.item])

    def test_duplicate_secret_targets_are_rejected(self):
        with self.assertRaises(ValueError):
            release.validate_inventory([self.item, dict(self.item)])

    def test_secret_exfiltration_destination_is_rejected(self):
        with self.assertRaises(ValueError):
            release.validate_inventory([dict(self.item, vault_uri="https://example.com")])

    def test_connections_are_not_replica_count(self):
        self.assertEqual(release.connected_replicas([
            {"id": "replica-1", "conns": [{"client_id": "replica-1"}] * 4},
            {"id": "replica-2", "conns": [{"client_id": "replica-2"}] * 4},
            {"id": "offline", "conns": []},
        ]), 2)

    def test_initial_creation_may_create_both_replicas(self):
        release.check_rollout({"resource_changes": [
            {"type": "azurerm_virtual_machine_run_command", "name": "cloudflared", "change": {"actions": ["create"]}}
        ] * 2})

    def test_rollout_rejects_two_existing_replicas(self):
        change = {"type": "azurerm_virtual_machine_run_command", "name": "cloudflared", "change": {
            "actions": ["update"], "before": {"tags": {"cloudflare_tunnel_scope": "same-tunnel"}},
            "after": {"tags": {"cloudflare_tunnel_scope": "same-tunnel"}},
        }}
        with self.assertRaises(ValueError):
            release.check_rollout({"resource_changes": [change, change]})

    def test_vm_replacement_requires_cutover(self):
        with self.assertRaises(ValueError):
            release.check_rollout({"resource_changes": [{"type": "azurerm_windows_virtual_machine", "change": {"actions": ["delete", "create"]}}]})

    @patch.object(release, "cloudflare", return_value="mock-token")
    @patch.object(release, "request_json", return_value={"value": "mock-token"})
    def test_unchanged_token_does_not_create_secret_version(self, request, cloudflare):
        release.sync_token(self.item, "mock-api", "mock-azure")
        self.assertEqual(request.call_count, 1)

    @patch.object(release, "cloudflare", return_value="new-mock-token")
    @patch.object(release, "request_json", side_effect=[{"value": "old-mock-token"}, {}])
    def test_changed_token_is_written_without_output(self, request, cloudflare):
        release.sync_token(self.item, "mock-api", "mock-azure")
        self.assertEqual(request.call_args.args[2], "PUT")
        self.assertEqual(request.call_args.args[3]["value"], "new-mock-token")


if __name__ == "__main__":
    unittest.main()
