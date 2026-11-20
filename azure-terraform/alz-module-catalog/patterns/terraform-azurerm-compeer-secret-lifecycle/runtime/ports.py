"""Azure ports. Credentials are held in memory and published directly to Key Vault."""
import json
import secrets
import threading
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
from urllib.parse import urlparse

import requests
from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient

from rotation import Intervention, Retryable, stamp


def retry_after(response):
    value = response.headers.get("Retry-After", "0")
    try:
        return max(0, float(value))
    except ValueError:
        try:
            return max(0, (parsedate_to_datetime(value) - datetime.now(timezone.utc)).total_seconds())
        except (TypeError, ValueError):
            return 0


class BlobStore:
    def __init__(self, endpoint, credential):
        self.container = BlobServiceClient(endpoint, credential=credential).get_container_client("execution")
        self.local = threading.local()

    def read(self, key):
        try:
            return json.loads(self.container.get_blob_client(key + ".json").download_blob().readall())
        except ResourceNotFoundError:
            return {}

    def keys(self):
        return (blob.name[:-5] for blob in self.container.list_blobs() if blob.name.endswith(".json"))

    @contextmanager
    def lock(self, key):
        blob = self.container.get_blob_client(key + ".json")
        try:
            blob.upload_blob("{}", overwrite=False)
        except ResourceExistsError:
            pass
        lease = blob.acquire_lease(lease_duration=60)
        stop, lost = threading.Event(), threading.Event()

        def renew():
            while not stop.wait(20):
                try:
                    lease.renew()
                except Exception:
                    lost.set()
                    return

        thread = threading.Thread(target=renew, daemon=True)
        self.local.lock = (key, lease, lost)
        thread.start()
        try:
            yield self.read(key)
        finally:
            stop.set()
            thread.join(timeout=25)
            self.local.lock = None
            lease.release()

    def save(self, key, state):
        held_key, lease, lost = self.local.lock
        if key != held_key or lost.is_set():
            raise Intervention("asset_lock_lost")
        self.container.get_blob_client(key + ".json").upload_blob(
            json.dumps(state), overwrite=True, lease=lease)


class AzureAuthority:
    def __init__(self, credential):
        self.credential = credential

    def call(self, scope, method, url, body=None):
        token = self.credential.get_token(scope).token
        response = requests.request(method, url, json=body,
                                    headers={"Authorization": "Bearer " + token},
                                    timeout=(10, 40), allow_redirects=False)
        # No exception includes a response payload or URL carrying secret material.
        if response.status_code not in (200, 201, 202, 204):
            raise Intervention("authority_permission_or_config") if response.status_code in (400, 401, 403, 404) else Retryable(retry_after(response))
        return response.json() if response.content else {}

    def vault(self, asset):
        return SecretClient(asset["vault_url"], self.credential, logging_enable=False)

    def precheck(self, asset):
        if asset["adapter"] not in ("storage_dual_key", "entra_application"):
            raise Intervention("unsupported_adapter")
        current = self.vault(asset).get_secret(asset["secret_name"])
        properties = current.properties
        tags = properties.tags or {}
        if tags.get("authority_id", "").lower() != asset["target"]["resource_id"].lower():
            raise Intervention("secret_authority_metadata_mismatch")
        credential_id = tags.get("credential_id")
        if not credential_id:
            raise Intervention("missing_current_credential_id")
        if asset["adapter"] == "storage_dual_key":
            if credential_id not in ("key1", "key2") or not asset["target"].get("alternate_key_unused_confirmed") == "true":
                raise Intervention("storage_alternate_key_not_proven_unused")
            if asset["target"].get("sas_dependencies_reviewed") != "true":
                raise Intervention("storage_sas_dependencies_unknown")
            keys = self.call("https://management.azure.com/.default", "POST",
                             "https://management.azure.com" + asset["target"]["resource_id"] + "/listKeys?api-version=2023-05-01")
            active = next(key["value"] for key in keys["keys"] if key["keyName"] == credential_id)
            if not secrets.compare_digest(active, current.value):
                raise Intervention("vault_does_not_match_authority")
        else:
            inventory = self.call("https://graph.microsoft.com/.default", "GET",
                                  "https://graph.microsoft.com/v1.0/applications/" + asset["target"]["resource_id"] + "?$select=passwordCredentials")
            if not any(item["keyId"] == credential_id for item in inventory["passwordCredentials"]):
                raise Intervention("previous_graph_credential_not_found")
        expires = getattr(properties, "expires_on", None)
        return {"credential_id": credential_id, "version": properties.version,
                "expires_at": stamp(expires) if expires else None}

    def create_publish(self, asset, state):
        target = asset["target"]["resource_id"]
        expires = datetime.now(timezone.utc) + timedelta(days=asset["credential_lifetime_days"])
        if asset["adapter"] == "storage_dual_key":
            new_id = "key2" if state["previous"]["credential_id"] == "key1" else "key1"
            result = self.call("https://management.azure.com/.default", "POST",
                               "https://management.azure.com" + target + "/regenerateKey?api-version=2023-05-01",
                               {"keyName": new_id})
            value = next(key["value"] for key in result["keys"] if key["keyName"] == new_id)
        else:
            result = self.call("https://graph.microsoft.com/.default", "POST",
                               "https://graph.microsoft.com/v1.0/applications/" + target + "/addPassword",
                               {"passwordCredential": {"displayName": "rotation-" + state["cycle"],
                                                       "endDateTime": stamp(expires)}})
            new_id, value = result["keyId"], result["secretText"]
        # If publication or checkpointing has an ambiguous outcome, resume by
        # inspecting version metadata. Never persist secretText into execution state.
        published = self.vault(asset).set_secret(asset["secret_name"], value, expires_on=expires,
            tags={"rotation_cycle": state["cycle"], "authority_id": target,
                  "credential_id": new_id, "managed_by": "compeer-rotation"}, logging_enable=False)
        return {"replacement_id": new_id, "version": published.properties.version}

    def reconcile_publication(self, asset, state):
        for properties in self.vault(asset).list_properties_of_secret_versions(asset["secret_name"]):
            tags = properties.tags or {}
            if tags.get("rotation_cycle") == state["cycle"]:
                return {"replacement_id": tags["credential_id"], "version": properties.version}
        return None

    def retire(self, asset, state):
        target = asset["target"]["resource_id"]
        if asset["adapter"] == "storage_dual_key":
            self.call("https://management.azure.com/.default", "POST",
                      "https://management.azure.com" + target + "/regenerateKey?api-version=2023-05-01",
                      {"keyName": state["previous"]["credential_id"]})
        else:
            self.call("https://graph.microsoft.com/.default", "POST",
                      "https://graph.microsoft.com/v1.0/applications/" + target + "/removePassword",
                      {"keyId": state["previous"]["credential_id"]})
        self.vault(asset).update_secret_properties(asset["secret_name"],
                                                  state["previous"]["version"], enabled=False)

    def verify_publication(self, asset, state):
        current = self.precheck(asset)
        if current["version"] != state["version"] or current["credential_id"] != state["replacement_id"]:
            raise Intervention("published_credential_changed_before_retirement")

    def retirement_confirmed(self, asset, state):
        if asset["adapter"] == "storage_dual_key":
            return False
        target = asset["target"]["resource_id"]
        result = self.call("https://graph.microsoft.com/.default", "GET",
                           "https://graph.microsoft.com/v1.0/applications/" + target + "?$select=passwordCredentials")
        if any(item["keyId"] == state["previous"]["credential_id"] for item in result["passwordCredentials"]):
            return False
        self.vault(asset).update_secret_properties(asset["secret_name"], state["previous"]["version"], enabled=False)
        return True


class Consumers:
    def __init__(self, credential, approved_hosts):
        self.credential, self.approved_hosts = credential, approved_hosts

    def invoke(self, consumer, stage, asset, state):
        url = consumer[stage + "_url"]
        parsed = urlparse(url)
        if (parsed.scheme != "https" or parsed.hostname not in self.approved_hosts
                or parsed.username or parsed.password or parsed.query or parsed.fragment):
            raise Intervention("unapproved_consumer_endpoint")
        token = self.credential.get_token(consumer["audience"].rstrip("/") + "/.default").token
        result = requests.post(url, headers={"Authorization": "Bearer " + token},
            json={"cycle": state["cycle"], "vault_url": asset["vault_url"],
                  "secret_name": asset["secret_name"], "version": state["version"], "stage": stage},
            timeout=(10, 30), allow_redirects=False)
        if result.status_code not in (200, 202):
            if result.status_code in (400, 401, 403, 404):
                raise Intervention("consumer_permission_or_config")
            raise Retryable(retry_after(result))
        if result.status_code == 202:
            return False
        evidence = result.json()
        return (evidence.get("cycle") == state["cycle"] and evidence.get("version") == state["version"]
                and evidence.get("healthy") is True
                and (stage != "validate" or evidence.get("fresh_authentication") is True))

    def adopt(self, asset, consumer, state):
        return self.invoke(consumer, "refresh", asset, state)

    def validate(self, asset, consumer, state):
        return self.invoke(consumer, "validate", asset, state)
