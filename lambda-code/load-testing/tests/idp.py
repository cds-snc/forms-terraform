"""
Tests the IdP's access token generation and introspection endpoints.
"""
import os
import json
from typing import Any, Dict

from locust import HttpUser, SequentialTaskSet, task, between
from urllib.parse import urlparse
from utils.jwt_generator import PrivateApiKey, JwtGenerator


class AccessTokenBehaviour(SequentialTaskSet):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)

        # Check for required environment variables
        private_key_app_json = os.getenv("PRIVATE_API_KEY_APP_JSON")
        private_key_user_json = os.getenv("PRIVATE_API_KEY_USER_JSON")
        if not private_key_app_json or not private_key_user_json:
            raise ValueError("PRIVATE_API_KEY_APP_JSON and PRIVATE_API_KEY_USER_JSON are required environment variables")

        parsed_url = urlparse(parent.host)
        self.idp_url = f"{parsed_url.scheme}://auth.{parsed_url.netloc}"
        self.idp_project_id = os.getenv("IDP_PROJECT_ID", "275372254274006635")
        self.private_api_key_app = PrivateApiKey.from_json(json.loads(private_key_app_json))
        self.private_api_key_user = PrivateApiKey.from_json(json.loads(private_key_user_json))
        self.jwt_app = None
        self.jwt_user = None
        self.access_token = None

    def on_start(self) -> None:
        self.jwt_app = JwtGenerator.generate(self.idp_url, self.private_api_key_app)
        self.jwt_user = JwtGenerator.generate(self.idp_url, self.private_api_key_user)

    def request_with_failure_check(self, method: str, url: str, status_code: int, **kwargs: Dict[str, Any]) -> dict:
        kwargs["catch_response"] = True
        with self.client.request(method, url, **kwargs) as response:
            if response.status_code != status_code:
                response.failure(f"Request failed: {response.status_code} {response.text}")
                raise ValueError(f"Request failed: {response.status_code} {response.text}")
            return response.json()

    @task
    def request_access_token(self) -> None:
        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": self.jwt_user,
            "scope": f"openid profile urn:zitadel:iam:org:project:id:{self.idp_project_id}:aud"
        }
        response = self.request_with_failure_check("post", f"{self.idp_url}/oauth/v2/token", 200, data=data)
        self.access_token = response["access_token"]

    @task
    def introspect_access_token(self) -> None:
        data = {
            "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            "client_assertion": self.jwt_app,
            "token": self.access_token,
        }
        self.request_with_failure_check("post", f"{self.idp_url}/oauth/v2/introspect", 200, data=data)


class IdpUser(HttpUser):
    tasks = [AccessTokenBehaviour]
    wait_time = between(1, 5)