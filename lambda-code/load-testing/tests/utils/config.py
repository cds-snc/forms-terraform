import os
import json
import random
from typing import Optional, Dict, Any
from pydantic import BaseModel
from urllib.parse import urlparse


class PrivateKey(BaseModel):
    keyId: str
    key: str
    userId: Optional[str] = None
    clientId: Optional[str] = None


class TestForm(BaseModel):
    id: str
    template: Dict[str, Any]
    apiPrivateKey: PrivateKey


class TestConfiguration(BaseModel):
    testForms: list[TestForm]
    submitFormServerActionIdentifier: str

    def get_random_test_form(self) -> TestForm:
        return random.choice(self.testForms)


def get_client_url_from_target_host(target_host: str) -> str:
    return target_host


def get_idp_url_from_target_host(target_host: str) -> str:
    parsed_url = urlparse(target_host)
    return f"{parsed_url.scheme}://auth.{parsed_url.netloc}"


def get_api_url_from_target_host(target_host: str) -> str:
    parsed_url = urlparse(target_host)
    return f"{parsed_url.scheme}://api.{parsed_url.netloc}"


def get_idp_project_id() -> str:
    return "275372254274006635"


def get_zitadel_app_private_key() -> PrivateKey:
    key = json.loads(require_env("ZITADEL_APP_PRIVATE_KEY").replace("\n", "\\n"))
    return PrivateKey(**key)


def require_env(name: str) -> str:
    value = os.getenv(name)

    if value is None:
        raise EnvironmentError(f"Required environment variable '{name}' is not set")

    return value


def load_test_configuration() -> TestConfiguration:
    try:
        with open("/tmp/test_configuration.json") as file:
            data = json.load(file)

        for form in data["testForms"]:
            form["template"] = json.loads(str(form["template"]).replace("\n", "\\n"))
            form["apiPrivateKey"] = json.loads(
                str(form["apiPrivateKey"]).replace("\n", "\\n")
            )

        return TestConfiguration(**data)
    except Exception as exception:
        raise Exception("Failed to load test configuration") from exception
