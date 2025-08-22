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
        test_configuration = load_test_configuration()
        random_test_form = (
            test_configuration.get_test_form_based_on_thread_id()
            if test_configuration.assignTestFormBasedOnThreadId
            else test_configuration.get_random_test_form()
        )
        self.form_id = random_test_form.id

        if random_test_form.apiKey is None:
            raise Exception("Test requires form API key")

        self.form_private_key = random_test_form.apiKey

        self.idp_project_id = get_idp_project_id()
        self.idp_url = get_idp_url_from_target_host(self.parent.host)
        self.api_url = get_api_url_from_target_host(self.parent.host)
        self.headers = None

    def on_start(self) -> None:
        jwt_form = JwtGenerator.generate(self.idp_url, self.form_private_key)

        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": jwt_form,
            "scope": f"openid profile urn:zitadel:iam:org:project:id:{self.idp_project_id}:aud",
        }

        response = self.request_with_failure_check(
            "post", f"{self.idp_url}/oauth/v2/token", 200, data=data
        )

        self.headers = {
            "Authorization": f"Bearer {response['access_token']}",
            "Content-Type": "application/json",
        }

    @task
    def get_new_submissions(self) -> None:
        form_new_submissions = self.request_with_failure_check(
            "get",
            f"{self.api_url}/forms/{self.form_id}/submission/new",
            200,
            headers=self.headers,
            name=f"/forms/submission/new",
        )

        self.get_form_template()

        while form_new_submissions:
            new_submission = form_new_submissions.pop(0)
            new_submission_name = new_submission["name"]
            submission = self.get_submission_by_name(new_submission_name)

            if "attachments" in submission:
                for attachment in submission["attachments"]:
                    self.download_submission_attachment(attachment["downloadLink"])

            self.confirm_submission(new_submission_name, submission["confirmationCode"])

    def get_form_template(self) -> None:
        self.request_with_failure_check(
            "get",
            f"{self.api_url}/forms/{self.form_id}/template",
            200,
            headers=self.headers,
            name=f"/forms/template",
        )

    def get_submission_by_name(self, submission_name: str) -> dict:
        response = self.request_with_failure_check(
            "get",
            f"{self.api_url}/forms/{self.form_id}/submission/{submission_name}",
            200,
            headers=self.headers,
            name=f"/forms/submission/retrieve",
        )

        encrypted_submission = EncryptedFormSubmission.from_json(response)
        decrypted_submission = FormSubmissionDecrypter.decrypt(
            encrypted_submission, self.form_private_key
        )

        return json.loads(decrypted_submission)

    def confirm_submission(self, submission_name: str, confirmation_code: str) -> None:
        self.request_with_failure_check(
            "put",
            f"{self.api_url}/forms/{self.form_id}/submission/{submission_name}/confirm/{confirmation_code}",
            200,
            headers=self.headers,
            name=f"/forms/submission/confirm",
        )

    def download_submission_attachment(self, download_link: str) -> None:
        self.request_with_failure_check(
            "get", download_link, 200, name="submission-attachment-download"
        )
