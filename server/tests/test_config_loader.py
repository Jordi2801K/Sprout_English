from pathlib import Path
import os
import tempfile
import unittest
from unittest.mock import patch

from app.config_loader import Settings


class ConfigLoaderTests(unittest.TestCase):
    def test_env_path_does_not_depend_on_working_directory(self):
        expected = Path(__file__).resolve().parents[1] / ".env"
        self.assertEqual(Settings.model_config["env_file"], expected)
        self.assertTrue(expected.is_absolute())

    def test_shared_env_accepts_api_settings_without_password_default(self):
        with tempfile.TemporaryDirectory() as directory:
            env_file = Path(directory) / ".env"
            env_file.write_text("DB_PORT=3307\nOPENAI_API_KEY=fixture-placeholder\n")
            with patch.dict(os.environ, {}, clear=True):
                settings = Settings(_env_file=env_file)
            self.assertEqual(settings.DB_PORT, 3307)
            self.assertEqual(settings.DB_PASSWORD, "")
