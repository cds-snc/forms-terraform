"""
Tests the Form submission flow through the client
"""

import json
import os
import re
from typing import Any, Dict
from locust import HttpUser, task
from utils.config import (
    get_client_url_from_target_host,
    load_test_configuration,
)
from utils.sequential_task_set_with_failure import SequentialTaskSetWithFailure
from utils.form_submission_generator import Attachments, FormSubmissionGenerator


class FormSubmitThroughClientBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        test_configuration = load_test_configuration()
        random_test_form = (
            test_configuration.get_test_form_based_on_thread_id()
            if test_configuration.assignTestFormBasedOnThreadId
            else test_configuration.get_random_test_form()
        )
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
        generated_response = self.form_submission_generator.generate_response()

        response = self.request_with_failure_check(
            "post",
            self.client_url,
            200,
            headers={"next-action": self.submit_form_server_action_id},
            name=f"nextjs-submit-form-server-action",
            data=f'[{json.dumps(generated_response.response_data)},"en","{self.form_id}","hcaptcha_token"]',
        )

        if len(generated_response.attachments) > 0:
            server_action_response_match = re.search(
                r'(\{"id".*?\}\}\}\})', str(response), re.DOTALL
            )

            signed_url_policy_match = re.findall(
                r"(\d+):[A-Z]\d{3},(.*?)(?=1:\{|\d:[A-Z]\d{3},)",
                str(response),
                re.DOTALL,
            )

            response_str = ""

            if server_action_response_match:
                response_str = server_action_response_match.group(1)

                if signed_url_policy_match:
                    for id, value in signed_url_policy_match:
                        response_str = response_str.replace(f"${id}", value)
                else:
                    raise ValueError(
                        "Failed to parse Policy parts of signed URL map object"
                    )

            else:
                raise ValueError(
                    "Failed to parse submitForm server action response but we need to upload submission attachments"
                )

            data = json.loads(response_str)

            self.upload_submission_attachments(
                generated_response.attachments, data["fileURLMap"]
            )

    def upload_submission_attachments(
        self, attachments: Attachments, file_url_map: Dict[str, Any]
    ) -> None:
        for attachment_id, attachment in attachments.items():
            if attachment_id not in file_url_map:
                raise KeyError(f"Key '{attachment_id}' not found in file URL map")

            upload_information = file_url_map[attachment_id]

            random_file = os.urandom(attachment.size)

            fields = upload_information["fields"]
            file = {"file": (attachment.name, random_file, "application/octet-stream")}

            self.request_with_failure_check(
                "post",
                upload_information["url"],
                204,
                name="submission-attachment-upload",
                data=fields,
                files=file,
            )
