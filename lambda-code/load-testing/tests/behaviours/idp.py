"""
Tests the IdP's access token generation and introspection endpoints.
"""

from locust import HttpUser, task
from utils.jwt_generator import JwtGenerator
from utils.task_set import SequentialTaskSetWithFailure


class AccessTokenBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        self.jwt_app = None
        self.jwt_user = None
        self.access_token = None

    def on_start(self) -> None:
        self.jwt_app = JwtGenerator.generate(self.idp_url, self.form_api_private_key)
        self.jwt_user = JwtGenerator.generate(self.idp_url, self.form_private_key)

    @task
    def request_access_token(self) -> None:
        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": self.jwt_user,
            "scope": f"openid profile urn:zitadel:iam:org:project:id:{self.idp_project_id}:aud",
        }
        response = self.request_with_failure_check(
            "post", f"{self.idp_url}/oauth/v2/token", 200, data=data
        )
        self.access_token = response["access_token"]

    @task
    def introspect_access_token(self) -> None:
        data = {
            "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            "client_assertion": self.jwt_app,
            "token": self.access_token,
        }
        self.request_with_failure_check(
            "post", f"{self.idp_url}/oauth/v2/introspect", 200, data=data
        )
