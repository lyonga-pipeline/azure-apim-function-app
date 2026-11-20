import base64
import json
import os
import unittest
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import Mock, patch

import azure.functions as func

# Import does not contact Azure; clients authenticate only when used.
os.environ.setdefault("ASSETS_JSON", "{}")
os.environ.setdefault("ROTATION_ENVIRONMENT", "nonprod")
os.environ.setdefault("AZURE_CLIENT_ID", "00000000-0000-0000-0000-000000000001")
os.environ.setdefault("STATE_BLOB_URL", "https://example.blob.core.windows.net")
import function_app as entry


class EntrypointTests(unittest.TestCase):
    def setUp(self):
        self.asset = dict(enabled=True, environment="nonprod", owner="owner", support_group="ops",
                          approval_reference="CHG", recovery_reference="runbook", adapter_approved=True,
                          consumer_inventory_reviewed=True, consumers=[{"name": "app"}],
                          initial_due=(datetime.now(timezone.utc) + timedelta(days=60)).isoformat(),
                          vault_url="https://example.vault.azure.net", secret_name="secret")
        self.approval = {"request-1": dict(asset_id="asset", mode="manual", approval_reference="CHG",
                         expires_at=(datetime.now(timezone.utc) + timedelta(hours=1)).isoformat(),
                         operator_object_ids=["approved-operator"], clean_identity_confirmed=False)}
        self.env = patch.dict(os.environ, {"TENANT_ID": "tenant", "APPROVALS_JSON": json.dumps(self.approval)})
        self.env.start()
        self.addCleanup(self.env.stop)
        self.asset_patch = patch.object(entry, "assets", {"asset": self.asset})
        self.asset_patch.start()
        self.addCleanup(self.asset_patch.stop)

    def request(self, tenant="tenant", actor="approved-operator", header=True):
        claims = {"claims": [{"typ": "tid", "val": tenant}, {"typ": "oid", "val": actor}]}
        headers = {"X-MS-CLIENT-PRINCIPAL": base64.b64encode(json.dumps(claims).encode()).decode()} if header else {}
        return func.HttpRequest("POST", "https://private/api/rotation/request", headers=headers,
                                body=json.dumps(dict(asset_id="asset", mode="manual", request_id="request-1")).encode())

    @patch.object(entry, "send")
    @patch.object(entry, "store")
    def test_approved_request_is_metadata_only(self, store, send):
        store.read.return_value = {}
        response = entry.request_rotation(self.request())
        self.assertEqual(response.status_code, 202)
        self.assertEqual(send.call_args.args[0]["approval_reference"], "CHG")

    @patch.object(entry, "send")
    def test_missing_wrong_tenant_and_unapproved_actor_rejected(self, send):
        for req in (self.request(header=False), self.request(tenant="other"), self.request(actor="other")):
            self.assertEqual(entry.request_rotation(req).status_code, 403)
        send.assert_not_called()

    @patch.object(entry, "send")
    @patch.object(entry, "store")
    def test_active_execution_returns_conflict(self, store, send):
        store.read.return_value = dict(phase="Creating", cycle="already-running")
        self.assertEqual(entry.request_rotation(self.request()).status_code, 409)
        send.assert_not_called()

    @patch.object(entry, "send")
    def test_disabled_asset_cannot_be_triggered_manually(self, send):
        self.asset["enabled"] = False
        self.assertEqual(entry.request_rotation(self.request()).status_code, 403)
        send.assert_not_called()

    @patch.object(entry, "AzureAuthority")
    @patch.object(entry, "send")
    @patch.object(entry, "store")
    def test_scheduler_metadata_only_expiry_scan(self, store, send, authority):
        store.keys.return_value = []
        store.read.return_value = {}
        authority.return_value.vault.return_value.list_properties_of_secrets.return_value = [
            SimpleNamespace(name="secret", expires_on=datetime.now(timezone.utc) + timedelta(days=7))]
        entry.reconcile(Mock())
        self.assertEqual(send.call_args.args[0]["mode"], "expiry_scan")
        authority.return_value.vault.return_value.get_secret.assert_not_called()

    def test_functions_are_discoverable(self):
        self.assertEqual({f.get_function_name() for f in entry.app.get_functions()},
                         {"rotate", "reconcile", "lifecycle_event", "request_rotation"})


if __name__ == "__main__":
    unittest.main()
