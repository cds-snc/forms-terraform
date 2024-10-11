"""
Tests the API's retrieval of new and specific responses.
"""
import os
import json
import random
from typing import Any, Dict

from locust import HttpUser, SequentialTaskSet, task, between
from urllib.parse import urlparse

from utils.data_structures import PrivateApiKey, EncryptedFormSubmission
from utils.form_submission_decrypter import FormSubmissionDecrypter
from utils.jwt_generator import JwtGenerator


class RetrieveResponseBehaviour(SequentialTaskSet):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)

        # Check for required environment variables
        form_id = os.getenv("FORM_ID")
        private_key_user_json = os.getenv("PRIVATE_API_KEY_USER_JSON")
        if not form_id or not private_key_user_json:
            raise ValueError("FORM_ID and PRIVATE_API_KEY_USER_JSON are required environment variables")

        parsed_url = urlparse(parent.host)
        self.api_url = f"{parsed_url.scheme}://api.{parsed_url.netloc}"
        self.idp_url = f"{parsed_url.scheme}://auth.{parsed_url.netloc}"
        self.idp_project_id = os.getenv("IDP_PROJECT_ID", "275372254274006635")
        self.private_api_key_user = PrivateApiKey.from_json(json.loads(private_key_user_json))
        self.form_id = form_id
        self.form_new_submissions = None
        self.form_decrypted_submissions = {}
        self.jwt_user = None
        self.access_token = None

    def request_with_failure_check(self, method: str, url: str, status_code: int, **kwargs: Dict[str, Any]) -> dict:
        kwargs["catch_response"] = True
        with self.client.request(method, url, **kwargs) as response:
            if response.status_code != status_code:
                response.failure(f"Request failed: {response.status_code} {response.text}")
                raise ValueError(f"Request failed: {response.status_code} {response.text}")
            return response.json() if "application/json" in response.headers.get("Content-Type", "") else response.text

    def on_start(self) -> None:
        self.jwt_user = JwtGenerator.generate(self.idp_url, self.private_api_key_user)
        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": self.jwt_user,
            "scope": f"openid profile urn:zitadel:iam:org:project:id:{self.idp_project_id}:aud"
        }
        response = self.request_with_failure_check("post", f"{self.idp_url}/oauth/v2/token", 200, data=data)
        self.access_token = response["access_token"]

    @task
    def get_new_submissions(self) -> None:
        headers = {
            "Authorization": f"Bearer {self.access_token}", 
            "Content-Type": "application/json"
        }
        self.form_new_submissions = self.request_with_failure_check("get", f"{self.api_url}/forms/{self.form_id}/submission/new", 200, headers=headers)

    @task
    def get_form_template(self) -> None:
        headers = {
            "Authorization": f"Bearer {self.access_token}", 
            "Content-Type": "application/json"
        }
        self.request_with_failure_check("get", f"{self.api_url}/forms/{self.form_id}/template", 200, headers=headers)

    @task
    def get_submission_by_name(self) -> None:
        headers = {
            "Authorization": f"Bearer {self.access_token}", 
            "Content-Type": "application/json"
        }
        submission = self.form_new_submissions.pop()
        response = self.request_with_failure_check("get", f"{self.api_url}/forms/{self.form_id}/submission/{submission["name"]}", 200, headers=headers)
        encrypted_submission = EncryptedFormSubmission.from_json(response)
        decrypted_submission = FormSubmissionDecrypter.decrypt(encrypted_submission, self.private_api_key_user)
        self.form_decrypted_submissions[submission["name"]] = json.loads(decrypted_submission)

    @task
    def confirm_submission(self) -> None:
        submission = self.form_decrypted_submissions.popitem()
        submission_name = submission[0]
        submission_data = submission[1]
        headers = {
            "Authorization": f"Bearer {self.access_token}", 
            "Content-Type": "application/json"
        }
        self.request_with_failure_check("put", f"{self.api_url}/forms/{self.form_id}/submission/{submission_name}/confirm/{submission_data['confirmationCode']}", 200, headers=headers)


class ApiUser(HttpUser):
    tasks = [RetrieveResponseBehaviour]
    wait_time = between(1, 5)