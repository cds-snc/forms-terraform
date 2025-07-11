"""
Tests the API's retrieval of new and specific responses.
"""

import json
from locust import HttpUser, task
from tests.utils.config import (
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
from tests.utils.sequential_task_set_with_failure import SequentialTaskSetWithFailure


class RetrieveResponseBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        test_configuration = load_test_configuration()
        random_test_form = test_configuration.get_random_test_form()
        self.form_id = random_test_form.id
        self.form_private_key = random_test_form.apiPrivateKey
        self.idp_project_id = get_idp_project_id()
        self.idp_url = get_idp_url_from_target_host(self.parent.host)
        self.api_url = get_api_url_from_target_host(self.parent.host)
        self.form_decrypted_submissions = {}
        self.form_new_submissions = None
        self.headers = None
        self.jwt_form = None

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
        self.headers = {
            "Authorization": f"Bearer {response['access_token']}",
            "Content-Type": "application/json",
        }

    @task
    def get_new_submissions(self) -> None:
        self.form_new_submissions = self.request_with_failure_check(
            "get",
            f"{self.api_url}/forms/{self.form_id}/submission/new",
            200,
            headers=self.headers,
            name=f"/forms/submission/new",
        )

    @task
    def get_form_template(self) -> None:
        self.request_with_failure_check(
            "get",
            f"{self.api_url}/forms/{self.form_id}/template",
            200,
            headers=self.headers,
            name=f"/forms/template",
        )

    @task
    def get_submission_by_name(self) -> None:
        submission = self.form_new_submissions.pop()
        response = self.request_with_failure_check(
            "get",
            f"{self.api_url}/forms/{self.form_id}/submission/{submission['name']}",
            200,
            headers=self.headers,
            name=f"/forms/submission/retrieve",
        )
        encrypted_submission = EncryptedFormSubmission.from_json(response)
        decrypted_submission = FormSubmissionDecrypter.decrypt(
            encrypted_submission, self.form_private_key
        )
        self.form_decrypted_submissions[submission["name"]] = json.loads(
            decrypted_submission
        )

    @task
    def confirm_submission(self) -> None:
        submission = self.form_decrypted_submissions.popitem()
        submission_name = submission[0]
        submission_data = submission[1]
        self.request_with_failure_check(
            "put",
            f"{self.api_url}/forms/{self.form_id}/submission/{submission_name}/confirm/{submission_data['confirmationCode']}",
            200,
            headers=self.headers,
            name=f"/forms/submission/confirm",
        )
