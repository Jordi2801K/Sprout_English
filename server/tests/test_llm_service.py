import importlib
import os
import unittest
from unittest.mock import patch


class LLMServiceTests(unittest.TestCase):
    def setUp(self):
        self._env = {
            "OPENAI_API_KEY": os.environ.get("OPENAI_API_KEY"),
            "LLM_MODE": os.environ.get("LLM_MODE"),
        }

    def tearDown(self):
        for key, value in self._env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    def _reload(self):
        import app.services.llm as llm
        return importlib.reload(llm)

    def test_openai_key_enables_llm_by_default(self):
        os.environ["OPENAI_API_KEY"] = "sk-test"
        os.environ.pop("LLM_MODE", None)

        llm = self._reload()

        self.assertTrue(llm.is_llm_available())

    def test_mock_mode_explicitly_disables_llm(self):
        os.environ["OPENAI_API_KEY"] = "sk-test"
        os.environ["LLM_MODE"] = "mock"

        llm = self._reload()

        self.assertFalse(llm.is_llm_available())

    def test_chat_json_uses_openai_when_key_exists(self):
        os.environ["OPENAI_API_KEY"] = "sk-test"
        os.environ.pop("LLM_MODE", None)
        llm = self._reload()

        with patch.object(llm, "_openai_chat", return_value='{"ok": true}') as chat:
            result = llm.chat_json("system", "user")

        self.assertEqual(result, {"ok": True})
        chat.assert_called_once()


if __name__ == "__main__":
    unittest.main()
