"""
Tests the Form submission flow through the reliability queue
"""

import os

from locust import HttpUser, task

from utils.form_submission_generator import FormSubmissionGenerator
from utils.jwt_generator import JwtGenerator
from utils.task_set import SequentialTaskSetWithFailure


class FormSubmitThroughInfraBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        self.access_token = None
        self.jwt_form = None
        self.form_id = os.getenv("FORM_ID")
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
        with self.parent.environment.events.request.measure(
            "task", "/forms/submit"
        ) as request_meta:
            self.form_submission_generator.submit_response()
