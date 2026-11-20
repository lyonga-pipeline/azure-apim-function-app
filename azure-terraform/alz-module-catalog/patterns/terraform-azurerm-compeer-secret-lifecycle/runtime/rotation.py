"""Metadata-only, resumable lifecycle engine. Cloud SDKs live in ports.py."""
import hashlib
import json
import random
from datetime import datetime, timedelta, timezone


class Intervention(Exception):
    """A human must reconcile authority/consumer evidence before continuing."""


class Retryable(Exception):
    def __init__(self, retry_after=0):
        self.retry_after = retry_after


def utc(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def stamp(value):
    return value.astimezone(timezone.utc).isoformat()


def cycle(asset_id, due):
    return hashlib.sha256(f"{asset_id}:{due}".encode()).hexdigest()[:32]


def eligible(asset, environment, now):
    if asset["environment"] != environment:
        raise Intervention("environment_mismatch")
    if not asset.get("enabled", False):
        raise Intervention("asset_disabled")
    if not all(asset.get(k) for k in ("owner", "support_group", "approval_reference", "recovery_reference")):
        raise Intervention("missing_governance")
    if not asset.get("consumers") or not asset.get("consumer_inventory_reviewed"):
        raise Intervention("unknown_consumers")
    exception = asset.get("exception_until")
    if exception:
        raise Intervention("exception_active" if utc(exception) > now else "exception_expired")
    if not asset.get("adapter_approved"):
        raise Intervention("adapter_not_approved")


def event_asset(event, assets):
    # Never react to SecretNewVersionCreated: that would rotate our own writes.
    if event.get("eventType") != "Microsoft.KeyVault.SecretNearExpiry":
        return None
    data = event.get("data", {})
    for key, asset in assets.items():
        if (event.get("topic", "").lower() == asset["vault_id"].lower()
                and data.get("ObjectName") == asset["secret_name"]
                and data.get("ObjectType") == "Secret"):
            return key
    return None


class Engine:
    def __init__(self, store, authority, consumers, environment, audit):
        self.store, self.authority, self.consumers = store, authority, consumers
        self.environment, self.audit = environment, audit

    def run(self, asset_id, asset, request, now):
        with self.store.lock(asset_id) as state:
            def save():
                state["updated_at"] = stamp(now)
                self.store.save(asset_id, state)
                self.audit(asset_id, state.get("cycle"), state["phase"], state.get("reason", ""))

            try:
                eligible(asset, self.environment, now)
                if state.get("phase") in ("ManualIntervention", "Failed"):
                    return
                fingerprint = hashlib.sha256(json.dumps(asset, sort_keys=True).encode()).hexdigest()
                if state.get("phase") not in (None, "Completed", "PrecheckRetry") and state.get("asset_fingerprint") != fingerprint:
                    raise Intervention("registry_changed_during_execution")
                if request["cycle"] in state.get("completed_cycles", []):
                    return
                if state.get("phase") == "Completed" and state["cycle"] == request["cycle"]:
                    return
                if state.get("retry_at") and now < utc(state["retry_at"]):
                    return
                if state.get("phase") == "PrecheckRetry" and state.get("cycle") != request["cycle"]:
                    return
                if state.get("phase") in (None, "Completed", "PrecheckRetry"):
                    if request["mode"] == "scheduled" and now < utc(state.get("next_due", asset["initial_due"])):
                        return
                    event_previous = None
                    if request["mode"] == "event":
                        event_previous = self.authority.precheck(asset)
                        if event_previous["version"] != request["expected_version"]:
                            return
                    if request["mode"] == "expiry_scan":
                        event_previous = self.authority.precheck(asset)
                        if not event_previous.get("expires_at") or utc(event_previous["expires_at"]) > now + timedelta(days=30):
                            return
                    if request["mode"] == "emergency" and not request.get("clean_identity_confirmed"):
                        raise Intervention("incident_requires_clean_identity")
                    completed_cycles = state.get("completed_cycles", [])
                    state.clear()
                    state.update(phase="Requested", cycle=request["cycle"], request=request,
                                 started_at=stamp(now), attempts=0, completed_cycles=completed_cycles,
                                 asset_fingerprint=fingerprint)
                    if event_previous:
                        state["previous"] = event_previous
                    save()
                # A second request must not replace an execution in flight.
                if state["cycle"] != request["cycle"]:
                    self.audit(asset_id, request["cycle"], "RequestConflict", "asset_execution_in_progress")
                    return
                phase = state["phase"]
                if phase == "Requested":
                    state["previous"] = state.get("previous") or self.authority.precheck(asset)
                    state["phase"] = "Prechecked"
                    save()
                if state["phase"] == "Prechecked":
                    # Persist intent before the non-transactional authority mutation.
                    state["phase"] = "Creating"
                    save()
                    result = self.authority.create_publish(asset, state)
                    state.update(result)
                    state["phase"] = "Published"
                    save()
                elif state["phase"] == "Creating":
                    result = self.authority.reconcile_publication(asset, state)
                    if result is None:
                        raise Intervention("ambiguous_creation_reconcile_orphan_at_authority")
                    state.update(result)
                    state["phase"] = "Published"
                    save()
                if state["phase"] in ("Published", "ConsumersUpdated"):
                    if now > utc(state["started_at"]) + timedelta(hours=asset["overlap_hours"]):
                        raise Intervention("consumer_adoption_deadline_exceeded")
                    results = [self.consumers.adopt(asset, c, state) for c in asset["consumers"]]
                    state["phase"] = "ConsumersUpdated"
                    save()
                    if not all(results):
                        return
                    # Each validator must prove fresh authentication with this version.
                    if not all(self.consumers.validate(asset, c, state) for c in asset["consumers"]):
                        return
                    state["phase"] = "Validated"
                    save()
                if state["phase"] == "Validated":
                    if now > utc(state["started_at"]) + timedelta(hours=asset["overlap_hours"]):
                        raise Intervention("retirement_deadline_exceeded")
                    if (state["request"]["mode"] != "emergency"
                            and now < utc(state["started_at"]) + timedelta(minutes=asset["minimum_overlap_minutes"])):
                        return
                    self.authority.verify_publication(asset, state)
                    if not all(self.consumers.validate(asset, c, state) for c in asset["consumers"]):
                        return
                    state["phase"] = "Retiring"
                    save()
                    self.authority.retire(asset, state)
                    state["phase"] = "PreviousRetired"
                    save()
                elif state["phase"] == "Retiring":
                    # Never blindly repeat destructive regeneration after an uncertain response.
                    if not self.authority.retirement_confirmed(asset, state):
                        raise Intervention("ambiguous_retirement_reconcile_authority")
                    state["phase"] = "PreviousRetired"
                    save()
                if state["phase"] == "PreviousRetired":
                    state.update(phase="Completed", attempts=0, retry_at=None,
                                 next_due=stamp(now + timedelta(days=asset["interval_days"])))
                    state["completed_cycles"] = state.get("completed_cycles", []) + [state["cycle"]]
                    save()
            except Intervention as error:
                state.update(phase="ManualIntervention", reason=str(error))
                save()
            except Exception as error:
                # Never log SDK exception messages: they can contain response bodies.
                if state.get("phase") in (None, "Completed"):
                    state.update(phase="PrecheckRetry", cycle=request["cycle"], request=request)
                state["attempts"] = state.get("attempts", 0) + 1
                state["reason"] = "operation_failed_check_authority_and_audit"
                if state["attempts"] >= 5 or getattr(error, "status_code", None) in (400, 401, 403, 404):
                    state["phase"] = "ManualIntervention"
                delay = min(3600, 60 * 2 ** state["attempts"]) + random.uniform(0, 30)
                delay = max(delay, getattr(error, "retry_after", 0))
                state["retry_at"] = stamp(now + timedelta(seconds=delay))
                save()


def scheduled_request(asset_id, asset, state, now):
    phase = state.get("phase")
    if phase in ("ManualIntervention", "Failed"):
        return None
    if phase not in (None, "Completed"):
        return state["request"]
    due = state.get("next_due", asset["initial_due"])
    if now < utc(due):
        return None
    return {"asset_id": asset_id, "cycle": cycle(asset_id, due), "mode": "scheduled"}


def manual_request(body, approvals, actor, now):
    approval = approvals.get(body.get("request_id"))
    if not approval or now >= utc(approval["expires_at"]):
        raise Intervention("approval_missing_or_expired")
    if approval["asset_id"] != body.get("asset_id") or approval["mode"] != body.get("mode"):
        raise Intervention("approval_scope_mismatch")
    if actor not in approval["operator_object_ids"]:
        raise Intervention("operator_not_approved")
    if approval["mode"] == "emergency" and not approval["clean_identity_confirmed"]:
        raise Intervention("incident_requires_clean_identity")
    return dict(asset_id=approval["asset_id"], cycle=body["request_id"], mode=approval["mode"],
                approval_reference=approval["approval_reference"], actor=actor,
                expires_at=approval["expires_at"], clean_identity_confirmed=approval["clean_identity_confirmed"])
