"""
Tests the IdP's access token generation and introspection endpoints.
"""

from locust import HttpUser, task
from utils.config import (
    get_zitadel_app_private_key,
    get_idp_project_id,
    get_idp_url_from_target_host,
    load_test_configuration,
)
from utils.jwt_generator import JwtGenerator
from utils.sequential_task_set_with_failure import SequentialTaskSetWithFailure


class AccessTokenBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        test_configuration = load_test_configuration()
        self.form_private_key = test_configuration.get_random_test_form().apiPrivateKey
        self.idp_url = get_idp_url_from_target_host(self.parent.host)
        self.idp_project_id = get_idp_project_id()
        self.zitadel_app_private_key = get_zitadel_app_private_key()
        self.jwt_app = None
        self.jwt_form = None
        self.access_token = None

    def on_start(self) -> None:
        self.jwt_app = JwtGenerator.generate(self.idp_url, self.zitadel_app_private_key)
        self.jwt_form = JwtGenerator.generate(self.idp_url, self.form_private_key)

    @task
    def request_access_token(self) -> None:
        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": self.jwt_form,
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
