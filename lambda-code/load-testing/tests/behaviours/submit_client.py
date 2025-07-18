"""
Tests the Form submission flow through the client
"""

import json
from locust import HttpUser, task
from utils.config import get_client_url_from_target_host, load_test_configuration
from utils.sequential_task_set_with_failure import SequentialTaskSetWithFailure
from utils.form_submission_generator import FormSubmissionGenerator


class FormSubmitThroughClientBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        test_configuration = load_test_configuration()
        random_test_form = test_configuration.get_random_test_form()
        self.form_id = random_test_form.id
        self.form_template = test_configuration.get_form_template(
            random_test_form.usedTemplate
        )
        self.client_url = get_client_url_from_target_host(self.parent.host)
        self.submit_form_server_action_id = (
            test_configuration.submitFormServerActionIdentifier
        )
        self.form_submission_generator = None

    def on_start(self) -> None:
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
            name=f"nextjs-submit-form-server-action",
            data=f'[{json.dumps(response_payload)},"en","{self.form_id}","hcaptcha_token"]',
        )
