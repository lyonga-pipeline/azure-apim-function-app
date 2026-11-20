import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class DeploymentTests(unittest.TestCase):
    def run_deploy(self, indexed):
        script = Path(__file__).resolve().parents[1] / "deploy.sh"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            az = root / "az"
            az.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$AZ_CALL_LOG"\n'
                          'if [ "$1" = functionapp ]; then printf "%s" "$INDEXED_JSON"; fi\n')
            sleep = root / "sleep"
            sleep.write_text("#!/bin/sh\nexit 0\n")
            az.chmod(0o755)
            sleep.chmod(0o755)
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ["PATH"],
                       ROTATION_RG="rotation-rg", ROTATION_APP="rotation-app", ROTATION_ZIP="package.zip",
                       ROTATION_SUBSCRIPTION="approved-subscription", AZ_CALL_LOG=str(root / "calls"),
                       INDEXED_JSON=json.dumps(indexed))
            result = subprocess.run(["bash", str(script)], env=env, capture_output=True, text=True, timeout=15)
            return result, (root / "calls").read_text()

    def test_explicit_subscription_and_complete_function_index(self):
        result, calls = self.run_deploy(["app/" + name for name in ("rotate", "reconcile", "lifecycle_event", "request_rotation")])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls.splitlines()), 2)
        self.assertTrue(all("--subscription approved-subscription" in call for call in calls.splitlines()))

    def test_successful_upload_with_missing_functions_is_failure(self):
        result, calls = self.run_deploy(["app/reconcile"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("indexing did not complete", result.stderr)
        self.assertEqual(len(calls.splitlines()), 19)


if __name__ == "__main__":
    unittest.main()
