import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch

from ports import AzureAuthority, Consumers, retry_after
from rotation import Intervention, Retryable


class PortTests(unittest.TestCase):
    def setUp(self):
        self.credential = Mock()
        self.credential.get_token.return_value.token = "DO-NOT-LOG"
        self.port = AzureAuthority(self.credential)
        self.vault = Mock()
        self.port.vault = Mock(return_value=self.vault)
        self.a = dict(adapter="storage_dual_key", secret_name="storage", credential_lifetime_days=90,
                      target=dict(resource_id="/storage/approved", alternate_key_unused_confirmed="true",
                                  sas_dependencies_reviewed="true"))
        self.current = SimpleNamespace(value="CURRENT-SECRET", properties=SimpleNamespace(
            tags={"authority_id": "/storage/approved", "credential_id": "key1"}, version="v1"))
        self.vault.get_secret.return_value = self.current
        self.state = {"cycle": "cycle-1", "previous": {"credential_id": "key1", "version": "v1"}}

    def test_storage_precheck_matches_authority(self):
        self.port.call = Mock(return_value={"keys": [{"keyName": "key1", "value": "CURRENT-SECRET"}]})
        self.assertEqual(self.port.precheck(self.a), dict(self.state["previous"], expires_at=None))

    def test_stale_vault_blocks_regeneration(self):
        self.port.call = Mock(return_value={"keys": [{"keyName": "key1", "value": "DIFFERENT"}]})
        with self.assertRaises(Intervention):
            self.port.precheck(self.a)

    def test_unknown_sas_or_active_alternate_blocks(self):
        for field in ("sas_dependencies_reviewed", "alternate_key_unused_confirmed"):
            self.a["target"][field] = "false"
            with self.assertRaises(Intervention):
                self.port.precheck(self.a)
            self.a["target"][field] = "true"

    def test_storage_publishes_alternate_only_and_returns_no_value(self):
        self.port.call = Mock(return_value={"keys": [{"keyName": "key2", "value": "NEW-SECRET"}]})
        self.vault.set_secret.return_value.properties.version = "v2"
        result = self.port.create_publish(self.a, self.state)
        self.assertEqual(result, {"replacement_id": "key2", "version": "v2"})
        self.assertEqual(self.port.call.call_args.args[-1], {"keyName": "key2"})
        self.assertEqual(self.vault.set_secret.call_args.args[1], "NEW-SECRET")
        self.assertNotIn("NEW-SECRET", str(result))

    def test_graph_add_and_retire_ids(self):
        self.a["adapter"] = "entra_application"
        self.a["target"]["resource_id"] = "app-object-id"
        self.port.call = Mock(return_value={"keyId": "new-key-id", "secretText": "ONE-TIME-SECRET"})
        self.vault.set_secret.return_value.properties.version = "v2"
        self.port.create_publish(self.a, self.state)
        self.assertIn("applications/app-object-id/addPassword", self.port.call.call_args.args[2])
        self.port.retire(self.a, self.state)
        self.assertEqual(self.port.call.call_args.args[-1], {"keyId": "key1"})

    def test_graph_reconcile_requires_previous_absent(self):
        self.a["adapter"] = "entra_application"
        self.port.call = Mock(return_value={"passwordCredentials": [{"keyId": "key1"}]})
        self.assertFalse(self.port.retirement_confirmed(self.a, self.state))
        self.port.call.return_value = {"passwordCredentials": []}
        self.assertTrue(self.port.retirement_confirmed(self.a, self.state))

    def test_storage_uncertain_retire_never_repeats(self):
        self.port.call = Mock()
        self.assertFalse(self.port.retirement_confirmed(self.a, self.state))
        self.port.call.assert_not_called()

    def test_publication_verification_rejects_a_changed_version(self):
        self.state.update(version="v2", replacement_id="key2")
        self.port.precheck = Mock(return_value={"version": "v2", "credential_id": "key2"})
        self.port.verify_publication(self.a, self.state)
        self.port.precheck.return_value["version"] = "external-change"
        with self.assertRaises(Intervention):
            self.port.verify_publication(self.a, self.state)

    @patch("ports.requests.request")
    def test_permission_errors_do_not_expose_response_body(self, request):
        request.return_value.status_code = 403
        request.return_value.content = b"SENSITIVE"
        with self.assertRaisesRegex(Intervention, "^authority_permission_or_config$"):
            self.port.call("scope", "POST", "https://management.azure.com/test")

    @patch("ports.requests.request")
    def test_retry_after_is_propagated(self, request):
        request.return_value.status_code = 429
        request.return_value.headers = {"Retry-After": "600"}
        with self.assertRaises(Retryable) as raised:
            self.port.call("scope", "POST", "https://management.azure.com/test")
        self.assertEqual(raised.exception.retry_after, 600)

    @patch("ports.requests.post")
    def test_validation_requires_matching_version_and_fresh_auth(self, post):
        consumers = Consumers(self.credential, ["consumer.internal"])
        consumer = dict(validate_url="https://consumer.internal/validate", audience="api://consumer")
        self.a["vault_url"] = "https://vault.vault.azure.net"
        self.state["version"] = "v2"
        post.return_value.status_code = 200
        post.return_value.json.return_value = dict(cycle="cycle-1", version="v1", healthy=True, fresh_authentication=True)
        self.assertFalse(consumers.validate(self.a, consumer, self.state))
        post.return_value.json.return_value["version"] = "v2"
        post.return_value.json.return_value["fresh_authentication"] = False
        self.assertFalse(consumers.validate(self.a, consumer, self.state))
        post.return_value.json.return_value["fresh_authentication"] = True
        self.assertTrue(consumers.validate(self.a, consumer, self.state))
        self.assertFalse(post.call_args.kwargs["allow_redirects"])
        self.assertNotIn("CURRENT-SECRET", str(post.call_args.kwargs["json"]))

    def test_unapproved_consumer_never_receives_token(self):
        consumers = Consumers(self.credential, ["consumer.internal"])
        for url in ("http://consumer.internal/validate", "https://attacker.invalid/validate",
                    "https://consumer.internal/validate?token=secret", "https://user:pass@consumer.internal/validate"):
            with self.assertRaises(Intervention):
                consumers.validate(self.a, dict(validate_url=url, audience="api://consumer"), self.state)
        self.credential.get_token.assert_not_called()


if __name__ == "__main__":
    unittest.main()
