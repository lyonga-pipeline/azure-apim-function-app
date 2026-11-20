"""Scheduler, private queue worker, and Entra-protected manual request entry point."""
import base64
import json
import logging
import os
from datetime import datetime, timedelta, timezone

import azure.functions as func
from azure.identity import ManagedIdentityCredential
from azure.servicebus import ServiceBusClient, ServiceBusMessage

from ports import AzureAuthority, BlobStore, Consumers
from rotation import Engine, Intervention, cycle, eligible, event_asset, manual_request, scheduled_request, utc

app = func.FunctionApp()
assets = json.loads(os.environ["ASSETS_JSON"])
environment = os.environ["ROTATION_ENVIRONMENT"]
credential = ManagedIdentityCredential(client_id=os.environ["AZURE_CLIENT_ID"])
store = BlobStore(os.environ["STATE_BLOB_URL"], credential)


def audit(asset_id, correlation, phase, reason=""):
    logging.info("ROTATION %s", json.dumps({"asset_id": asset_id, "correlation_id": correlation,
                  "phase": phase, "reason": reason, "environment": environment}))


def send(request):
    with ServiceBusClient(os.environ["BUS_NAMESPACE"], credential) as client:
        with client.get_queue_sender(os.environ["WORK_QUEUE"]) as sender:
            # Message ID includes a minute bucket: duplicate suppression within a
            # burst, but reconciliation must be able to redeliver the same cycle.
            bucket = datetime.now(timezone.utc).strftime("%Y%m%d%H%M")
            sender.send_messages(ServiceBusMessage(json.dumps(request),
                message_id=request["cycle"] + ":" + bucket, content_type="application/json"))


@app.timer_trigger(schedule="0 */5 * * * *", arg_name="timer", use_monitor=True)
def reconcile(timer: func.TimerRequest):
    now = datetime.now(timezone.utc)
    metadata = {}
    for key in store.keys():
        if key not in assets and store.read(key).get("phase") not in (None, "Completed"):
            audit(key, None, "GovernanceBlocked", "unregistered_incomplete_execution")
    for key, asset in assets.items():
        if not asset["enabled"]:
            continue
        try:
            eligible(asset, environment, now)
            state = store.read(key)
            if state.get("phase") == "ManualIntervention":
                audit(key, state.get("cycle"), "ManualIntervention", state.get("reason"))
            request = scheduled_request(key, asset, state, now)
            # Key Vault Reader lists metadata only; scheduler cannot fetch values.
            if asset["vault_url"] not in metadata:
                metadata[asset["vault_url"]] = {p.name: p for p in AzureAuthority(credential).vault(asset).list_properties_of_secrets()}
            current = metadata[asset["vault_url"]].get(asset["secret_name"])
            if current is None:
                audit(key, None, "GovernanceBlocked", "registered_secret_missing")
                continue
            if (not request and state.get("phase") in (None, "Completed") and current.expires_on
                    and current.expires_on <= now + timedelta(days=30)):
                request = dict(asset_id=key, mode="expiry_scan", cycle=cycle(key, "expiry:" + current.expires_on.isoformat()))
            if request:
                send(request)
            due = utc(state.get("next_due", asset["initial_due"]))
            effective_due = min(due, current.expires_on) if current.expires_on else due
            days = (effective_due - now).total_seconds() / 86400
            if days <= 30:
                reason = "7_days" if days <= 7 else "14_days" if days <= 14 else "30_days"
                overdue = (due < now - timedelta(hours=1)
                           or (current.expires_on is not None and current.expires_on < now))
                audit(key, state.get("cycle"), "Overdue" if overdue else "DueSoon", reason)
        except Intervention as error:
            audit(key, None, "GovernanceBlocked", str(error))
        except Exception:
            audit(key, None, "SchedulerFailure", "metadata_or_queue_unavailable")
            raise RuntimeError("reconciliation_failed") from None
    audit("platform", None, "Heartbeat")


@app.service_bus_queue_trigger(arg_name="message", queue_name="%WORK_QUEUE%", connection="RotationBus")
def rotate(message: func.ServiceBusMessage):
    request = json.loads(message.get_body())
    key = request["asset_id"]
    if key not in assets:
        raise ValueError("unregistered_asset")
    if request["mode"] not in ("scheduled", "expiry_scan", "event", "manual", "emergency"):
        raise ValueError("unsupported_trigger")
    # Manual approvals are revalidated at execution, not just HTTP intake.
    if request["mode"] in ("manual", "emergency"):
        state = store.read(key)
        if state.get("cycle") != request["cycle"]:
            manual_request({"request_id": request["cycle"], "asset_id": key, "mode": request["mode"]},
                           json.loads(os.environ["APPROVALS_JSON"]), request["actor"], datetime.now(timezone.utc))
    Engine(store, AzureAuthority(credential),
           Consumers(credential, json.loads(os.environ["CONSUMER_HOSTS_JSON"])), environment, audit).run(
        key, assets[key], request, datetime.now(timezone.utc))


@app.service_bus_queue_trigger(arg_name="message", queue_name="%EVENT_QUEUE%", connection="RotationBus")
def lifecycle_event(message: func.ServiceBusMessage):
    payload = json.loads(message.get_body())
    for event in payload if isinstance(payload, list) else [payload]:
        key = event_asset(event, assets)
        if key:
            now = datetime.now(timezone.utc)
            try:
                eligible(assets[key], environment, now)
                properties = AzureAuthority(credential).vault(assets[key]).get_secret(assets[key]["secret_name"]).properties
                # Re-read expiry/version; event payload is not authoritative.
                if (properties.version == event["data"].get("Version") and properties.expires_on
                        and properties.expires_on <= now + timedelta(days=30)):
                    send(dict(asset_id=key, mode="event", expected_version=properties.version,
                              cycle=cycle(key, "expiry:" + properties.version)))
            except Intervention as error:
                audit(key, None, "GovernanceBlocked", str(error))


@app.route(route="rotation/request", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def request_rotation(req: func.HttpRequest):
    # Easy Auth is mandatory and the Function App has no public endpoint.
    # Header identity is trusted only behind that platform-authenticated boundary.
    try:
        principal = json.loads(base64.b64decode(req.headers["X-MS-CLIENT-PRINCIPAL"]))
        claims = {item["typ"]: item["val"] for item in principal["claims"]}
        actor = claims.get("http://schemas.microsoft.com/identity/claims/objectidentifier", claims.get("oid"))
        tenant = claims.get("http://schemas.microsoft.com/identity/claims/tenantid", claims.get("tid"))
        if tenant != os.environ["TENANT_ID"] or not actor:
            return func.HttpResponse(status_code=403)
        request = manual_request(req.get_json(), json.loads(os.environ["APPROVALS_JSON"]), actor,
                                 datetime.now(timezone.utc))
        if request["asset_id"] not in assets:
            return func.HttpResponse("Unregistered asset", status_code=403)
        eligible(assets[request["asset_id"]], environment, datetime.now(timezone.utc))
        state = store.read(request["asset_id"])
        if state.get("phase") not in (None, "Completed") and state.get("cycle") != request["cycle"]:
            return func.HttpResponse("Asset already has an execution requiring completion or reconciliation", status_code=409)
        send(request)
        audit(request["asset_id"], request["cycle"], "ApprovedRequest", request["mode"])
        return func.HttpResponse(json.dumps({"correlation_id": request["cycle"]}), status_code=202)
    except (KeyError, ValueError, Intervention):
        return func.HttpResponse("Invalid or unapproved request", status_code=403)
