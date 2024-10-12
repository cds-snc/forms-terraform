"""
Tests the Form submission flow through the reliability queue
"""
import os
import json
from typing import Any, Dict

from locust import HttpUser, task, between
from urllib.parse import urlparse

from utils.form_submission_generator import FormSubmissionGenerator
from utils.jwt_generator import PrivateApiKey, JwtGenerator
from utils.task_set import SequentialTaskSetWithFailure


class FormSubmitBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)

        # Check for required environment variables
        form_id = os.getenv("FORM_ID")
        private_key_user_json = os.getenv("PRIVATE_API_KEY_USER_JSON")
        if not form_id or not private_key_user_json:
            raise ValueError("FORM_ID and PRIVATE_API_KEY_USER_JSON are required environment variables")
        self.form_id = form_id
        self.private_api_key_user = PrivateApiKey.from_json(json.loads(private_key_user_json))
        parsed_url = urlparse(parent.host)
        self.api_url = f"{parsed_url.scheme}://api.{parsed_url.netloc}"
        self.idp_url = f"{parsed_url.scheme}://auth.{parsed_url.netloc}"
        self.idp_project_id = os.getenv("IDP_PROJECT_ID", "275372254274006635")
        self.jwt_user = None
        self.access_token = None
        self.form_template = None
        self.form_submission_generator = None

    def on_start(self) -> None:
        self.jwt_user = JwtGenerator.generate(self.idp_url, self.private_api_key_user)
        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": self.jwt_user,
            "scope": f"openid profile urn:zitadel:iam:org:project:id:{self.idp_project_id}:aud"
        }
        response = self.request_with_failure_check("post", f"{self.idp_url}/oauth/v2/token", 200, data=data)
        self.access_token = response["access_token"]
        headers = {
            "Authorization": f"Bearer {self.access_token}", 
            "Content-Type": "application/json"
        }
        self.form_template = self.request_with_failure_check("get", f"{self.api_url}/forms/{self.form_id}/template", 200, headers=headers)
        self.form_submission_generator = FormSubmissionGenerator(self.form_id, self.form_template)

    @task
    def submit_response(self) -> None:
        with self.parent.environment.events.request.measure("task", "submit_response") as request_meta:
            self.form_submission_generator.submit_response()


class FormSubmitUser(HttpUser):
    tasks = [FormSubmitBehaviour]
    wait_time = between(1, 5)