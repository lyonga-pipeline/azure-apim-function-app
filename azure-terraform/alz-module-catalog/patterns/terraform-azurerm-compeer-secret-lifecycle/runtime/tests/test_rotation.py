import copy
import unittest
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from unittest.mock import Mock

from rotation import Engine, Intervention, cycle, eligible, event_asset, manual_request, scheduled_request, stamp

NOW = datetime(2026, 11, 19, tzinfo=timezone.utc)


def asset():
    return dict(enabled=True, environment="nonprod", owner="owner", support_group="ops",
                approval_reference="CHG1", recovery_reference="runbook", adapter_approved=True,
                consumer_inventory_reviewed=True, exception_until=None, initial_due=stamp(NOW),
                interval_days=45, overlap_hours=24, minimum_overlap_minutes=0,
                vault_id="/vault/approved", secret_name="storage", consumers=[{"name": "app"}])


class Store:
    def __init__(self):
        self.state = {}
        self.phases = []

    @contextmanager
    def lock(self, key):
        yield self.state

    def save(self, key, state):
        self.phases.append(state["phase"])


class RotationTests(unittest.TestCase):
    def setUp(self):
        self.store = Store()
        self.authority = Mock()
        self.authority.precheck.return_value = {"credential_id": "key1", "version": "old"}
        self.authority.create_publish.return_value = {"replacement_id": "key2", "version": "new"}
        self.consumers = Mock()
        self.consumers.adopt.return_value = True
        self.consumers.validate.return_value = True
        self.engine = Engine(self.store, self.authority, self.consumers, "nonprod", Mock())
        self.a = asset()
        self.request = scheduled_request("asset", self.a, {}, NOW)

    def run_rotation(self, now=NOW):
        self.engine.run("asset", self.a, self.request, now)

    def test_success_and_duplicate_do_not_mutate_twice(self):
        self.run_rotation()
        self.assertEqual(self.store.state["phase"], "Completed")
        self.run_rotation()
        self.authority.create_publish.assert_called_once()
        self.authority.retire.assert_called_once()

    def test_failed_adoption_preserves_previous(self):
        self.consumers.adopt.return_value = False
        self.run_rotation()
        self.assertEqual(self.store.state["phase"], "ConsumersUpdated")
        self.authority.retire.assert_not_called()

    def test_failed_validation_preserves_previous(self):
        self.consumers.validate.return_value = False
        self.run_rotation()
        self.authority.retire.assert_not_called()

    def test_resume_consumers_does_not_create_again(self):
        self.consumers.adopt.return_value = False
        self.run_rotation()
        self.consumers.adopt.return_value = True
        self.run_rotation()
        self.authority.create_publish.assert_called_once()
        self.assertEqual(self.store.state["phase"], "Completed")

    def test_registry_change_during_execution_blocks_retirement(self):
        self.consumers.adopt.return_value = False
        self.run_rotation()
        self.a["secret_name"] = "different-target"
        self.run_rotation()
        self.assertEqual(self.store.state["reason"], "registry_changed_during_execution")
        self.authority.retire.assert_not_called()

    def test_expired_adoption_escalates(self):
        self.consumers.validate.return_value = False
        self.run_rotation()
        self.run_rotation(NOW + timedelta(hours=25))
        self.assertEqual(self.store.state["phase"], "ManualIntervention")
        self.authority.retire.assert_not_called()

    def test_ambiguous_creation_requires_reconciliation(self):
        self.authority.create_publish.side_effect = RuntimeError("SECRET RESPONSE MUST NOT BE LOGGED")
        self.authority.reconcile_publication.return_value = None
        self.run_rotation()
        self.run_rotation(NOW + timedelta(minutes=10))
        self.assertEqual(self.store.state["phase"], "ManualIntervention")
        self.authority.create_publish.assert_called_once()
        self.assertNotIn("SECRET", str(self.store.state))

    def test_ambiguous_publish_can_recover_from_vault_metadata(self):
        self.authority.create_publish.side_effect = RuntimeError()
        self.run_rotation()
        self.authority.reconcile_publication.return_value = {"replacement_id": "key2", "version": "new"}
        self.run_rotation(NOW + timedelta(minutes=10))
        self.assertEqual(self.store.state["phase"], "Completed")

    def test_ambiguous_retirement_is_not_blindly_retried(self):
        self.authority.retire.side_effect = RuntimeError()
        self.authority.retirement_confirmed.return_value = False
        self.run_rotation()
        self.run_rotation(NOW + timedelta(minutes=10))
        self.assertEqual(self.store.state["phase"], "ManualIntervention")
        self.authority.retire.assert_called_once()

    def test_minimum_overlap_waits_without_holding_worker(self):
        self.a["minimum_overlap_minutes"] = 15
        self.run_rotation()
        self.authority.retire.assert_not_called()
        self.run_rotation(NOW + timedelta(minutes=16))
        self.authority.retire.assert_called_once()

    def test_missing_consumer_inventory_blocks(self):
        self.a["consumer_inventory_reviewed"] = False
        self.run_rotation()
        self.authority.create_publish.assert_not_called()

    def test_cross_environment_blocks(self):
        self.a["environment"] = "prod"
        self.run_rotation()
        self.authority.create_publish.assert_not_called()

    def test_exception_active_and_expired_block(self):
        for offset in (-1, 1):
            a = asset()
            a["exception_until"] = stamp(NOW + timedelta(days=offset))
            with self.assertRaises(Intervention):
                eligible(a, "nonprod", NOW)

    def test_future_due_not_queued(self):
        self.assertIsNone(scheduled_request("asset", self.a, {"next_due": stamp(NOW + timedelta(days=1))}, NOW))

    def test_transient_event_precheck_persists_retry_context(self):
        self.request.update(mode="event", expected_version="old")
        self.authority.precheck.side_effect = RuntimeError("SENSITIVE")
        self.run_rotation()
        self.assertEqual(self.store.state["phase"], "PrecheckRetry")
        self.assertEqual(scheduled_request("asset", self.a, self.store.state, NOW), self.request)
        self.authority.precheck.side_effect = None
        self.run_rotation(NOW + timedelta(minutes=5))
        self.assertEqual(self.store.state["phase"], "Completed")

    def test_health_regression_during_overlap_blocks_retirement(self):
        self.a["minimum_overlap_minutes"] = 15
        self.run_rotation()
        self.consumers.validate.return_value = False
        self.run_rotation(NOW + timedelta(minutes=16))
        self.authority.retire.assert_not_called()
        self.run_rotation(NOW + timedelta(hours=25))
        self.assertEqual(self.store.state["reason"], "retirement_deadline_exceeded")

    def test_changed_publication_blocks_retirement(self):
        self.authority.verify_publication.side_effect = Intervention("published_credential_changed_before_retirement")
        self.run_rotation()
        self.authority.retire.assert_not_called()

    def test_verified_expiry_event_can_advance_rotation(self):
        self.a["initial_due"] = stamp(NOW + timedelta(days=30))
        self.request.update(mode="event", expected_version="old")
        self.run_rotation()
        self.assertEqual(self.store.state["phase"], "Completed")

    def test_stale_expiry_event_does_not_change_state(self):
        self.request.update(mode="event", expected_version="stale")
        self.run_rotation()
        self.assertEqual(self.store.state, {})
        self.authority.create_publish.assert_not_called()

    def test_incomplete_execution_is_requeued(self):
        self.consumers.adopt.return_value = False
        self.run_rotation()
        self.assertEqual(scheduled_request("asset", self.a, self.store.state, NOW), self.request)

    def test_new_version_does_not_loop(self):
        self.assertIsNone(event_asset({"eventType": "Microsoft.KeyVault.SecretNewVersionCreated"}, {"a": self.a}))

    def test_event_rejects_wrong_vault_and_secret(self):
        event = {"eventType": "Microsoft.KeyVault.SecretNearExpiry", "topic": "/vault/approved",
                 "data": {"ObjectType": "Secret", "ObjectName": "storage"}}
        self.assertEqual(event_asset(event, {"a": self.a}), "a")
        event["topic"] = "/vault/untrusted"
        self.assertIsNone(event_asset(event, {"a": self.a}))

    def test_manual_scope_actor_and_expiry(self):
        approval = dict(asset_id="asset", mode="manual", expires_at=stamp(NOW + timedelta(hours=1)),
                        operator_object_ids=["operator"], approval_reference="CHG", clean_identity_confirmed=False)
        body = dict(asset_id="asset", mode="manual", request_id="request-1")
        result = manual_request(body, {"request-1": approval}, "operator", NOW)
        self.assertEqual(result["cycle"], "request-1")
        with self.assertRaises(Intervention):
            manual_request(body, {"request-1": approval}, "someone", NOW)
        with self.assertRaises(Intervention):
            manual_request(body, {"request-1": approval}, "operator", NOW + timedelta(days=1))

    def test_emergency_requires_clean_identity(self):
        self.request.update(mode="emergency", clean_identity_confirmed=False)
        self.run_rotation()
        self.assertEqual(self.store.state["reason"], "incident_requires_clean_identity")

    def test_approved_emergency_retires_after_validation_without_planned_overlap(self):
        self.a["minimum_overlap_minutes"] = 60
        self.request.update(mode="emergency", clean_identity_confirmed=True)
        self.run_rotation()
        self.authority.retire.assert_called_once()
        self.assertEqual(self.store.state["phase"], "Completed")

    def test_expiry_scan_rechecks_current_metadata(self):
        self.a["initial_due"] = stamp(NOW + timedelta(days=50))
        self.request.update(mode="expiry_scan")
        self.authority.precheck.return_value["expires_at"] = stamp(NOW + timedelta(days=60))
        self.run_rotation()
        self.authority.create_publish.assert_not_called()
        self.authority.precheck.return_value["expires_at"] = stamp(NOW + timedelta(days=20))
        self.run_rotation()
        self.assertEqual(self.store.state["phase"], "Completed")

    def test_retry_budget_escalates_without_secret_exception(self):
        self.authority.precheck.side_effect = RuntimeError("SENSITIVE")
        for i in range(5):
            self.run_rotation(NOW + timedelta(hours=i))
        self.assertEqual(self.store.state["phase"], "ManualIntervention")
        self.assertNotIn("SENSITIVE", str(self.store.state))

    def test_completed_approval_cannot_replay_after_another_cycle(self):
        self.run_rotation()
        old_request = copy.deepcopy(self.request)
        self.request = dict(asset_id="asset", mode="manual", cycle="second")
        self.run_rotation()
        self.request = old_request
        self.run_rotation()
        self.assertEqual(self.authority.create_publish.call_count, 2)

    def test_cycle_is_stable(self):
        self.assertEqual(cycle("asset", "date"), cycle("asset", "date"))
        self.assertNotEqual(cycle("asset", "date"), cycle("asset", "other-date"))


if __name__ == "__main__":
    unittest.main()
