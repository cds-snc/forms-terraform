"""
Tests the API's retrieval of new and specific responses.
"""

import json
from locust import HttpUser, task
from utils.config import (
    get_idp_project_id,
    get_idp_url_from_target_host,
    get_api_url_from_target_host,
    load_test_configuration,
)
from utils.form_submission_decrypter import (
    EncryptedFormSubmission,
    FormSubmissionDecrypter,
)
from utils.jwt_generator import JwtGenerator
from utils.sequential_task_set_with_failure import SequentialTaskSetWithFailure


class RetrieveResponseBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        self.test_configuration = load_test_configuration()
        self.idp_project_id = get_idp_project_id()
        self.idp_url = get_idp_url_from_target_host(self.parent.host)
        self.api_url = get_api_url_from_target_host(self.parent.host)
        self.headers = None

    def on_start(self) -> None:
        random_test_form = (
            self.test_configuration.get_test_form_based_on_thread_id()
            if self.test_configuration.assignTestFormBasedOnThreadId
            else self.test_configuration.get_random_test_form()
        )

        self.form_id = random_test_form.id

        if random_test_form.apiKey is None:
            raise Exception("Test requires form API key")

        self.form_private_key = random_test_form.apiKey

        jwt_form = JwtGenerator.generate(self.idp_url, self.form_private_key)

        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": jwt_form,
            "scope": f"openid profile urn:zitadel:iam:org:project:id:{self.idp_project_id}:aud",
        }

        response = self.request_with_failure_check(
            method="post",
            url=f"{self.idp_url}/oauth/v2/token",
            expected_status_code=200,
            request_tracking_name="oauth/v2/token",
            data=data,
        )

        self.headers = {
            "Authorization": f"Bearer {response['access_token']}",
            "Content-Type": "application/json",
        }

        self.request_with_failure_check(
            method="get",
            url=f"{self.api_url}/forms/{self.form_id}/template",
            expected_status_code=200,
            request_tracking_name="/forms/template",
            headers=self.headers,
        )

    @task
    def get_new_submissions(self) -> None:
        form_new_submissions = self.request_with_failure_check(
            method="get",
            url=f"{self.api_url}/forms/{self.form_id}/submission/new",
            expected_status_code=200,
            request_tracking_name="/forms/submission/new",
            headers=self.headers,
        )

        while form_new_submissions:
            new_submission = form_new_submissions.pop(0)
            new_submission_name = new_submission["name"]
            submission = self.get_submission_by_name(new_submission_name)
            self.confirm_submission(new_submission_name, submission["confirmationCode"])

    def get_submission_by_name(self, submission_name: str) -> dict:
        response = self.request_with_failure_check(
            method="get",
            url=f"{self.api_url}/forms/{self.form_id}/submission/{submission_name}",
            expected_status_code=200,
            request_tracking_name="/forms/submission/retrieve",
            headers=self.headers,
        )

        encrypted_submission = EncryptedFormSubmission.from_json(response)
        decrypted_submission = FormSubmissionDecrypter.decrypt(
            encrypted_submission, self.form_private_key
        )

        return json.loads(decrypted_submission)

    def confirm_submission(self, submission_name: str, confirmation_code: str) -> None:
        self.request_with_failure_check(
            method="put",
            url=f"{self.api_url}/forms/{self.form_id}/submission/{submission_name}/confirm/{confirmation_code}",
            expected_status_code=200,
            request_tracking_name="/forms/submission/confirm",
            headers=self.headers,
        )
