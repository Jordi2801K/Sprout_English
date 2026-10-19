import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class ServerImportTests(unittest.TestCase):
    def test_import_creates_missing_runtime_storage(self):
        server = Path(__file__).resolve().parents[1]
        env = {**os.environ, "PYTHONPATH": str(server), "PYTHONDONTWRITEBYTECODE": "1"}
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [sys.executable, "-B", "-c", "from app.main import app"],
                cwd=directory,
                env=env,
                capture_output=True,
                timeout=30,
            )
            # Do not include captured config/errors, which can contain credentials.
            self.assertEqual(result.returncode, 0)
            self.assertTrue((Path(directory) / "app/storage").is_dir())
