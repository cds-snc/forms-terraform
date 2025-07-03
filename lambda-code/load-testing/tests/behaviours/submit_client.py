"""
Tests the Form submission flow through the client
"""

import os
import json

from locust import HttpUser, task

from utils.form_submission_generator import FormSubmissionGenerator
from utils.jwt_generator import JwtGenerator
from utils.task_set import SequentialTaskSetWithFailure


class FormSubmitThroughClientBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        self.access_token = None
        self.jwt_form = None
        self.form_id = os.getenv("FORM_ID")
        self.submit_form_server_action_id = os.getenv("SUBMIT_FORM_SERVER_ACTION_ID")
        self.form_template = None
        self.form_submission_generator = None

    def on_start(self) -> None:
        self.jwt_form = JwtGenerator.generate(self.idp_url, self.form_private_key)
        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": self.jwt_form,
            "scope": f"openid profile urn:zitadel:iam:org:project:id:{self.idp_project_id}:aud",
        }
        response = self.request_with_failure_check(
            "post", f"{self.idp_url}/oauth/v2/token", 200, data=data
        )
        self.access_token = response["access_token"]
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json",
        }
        self.form_template = self.request_with_failure_check(
            "get",
            f"{self.api_url}/forms/{self.form_id}/template",
            200,
            headers=headers,
            name=f"/forms/template",
        )
        self.form_submission_generator = FormSubmissionGenerator(
            self.form_id, self.form_template
        )

    @task
    def submit_response(self) -> None:
        response_payload = self.form_submission_generator.generate_response()
        self.request_with_failure_check(
            "post",
            self.client_url,
            200,
            headers={"next-action": self.submit_form_server_action_id},
            name=f"next-js-submit-form-server-action",
            data=f'[{json.dumps(response_payload)},"en","{self.form_id}","hcaptcha_token"]',
        )
