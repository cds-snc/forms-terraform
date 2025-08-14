"""
Tests the Form submission flow through the reliability queue
"""

import json
import os
from typing import Any, Dict
from locust import HttpUser, task
from utils.config import load_test_configuration
from utils.sequential_task_set_with_failure import SequentialTaskSetWithFailure
from utils.form_submission_generator import Attachments, FormSubmissionGenerator
from botocore.config import Config
from boto3 import client


class FormSubmitThroughInfraBehaviour(SequentialTaskSetWithFailure):
    def __init__(self, parent: HttpUser) -> None:
        super().__init__(parent)
        test_configuration = load_test_configuration()
        random_test_form = test_configuration.get_random_test_form()
        self.form_id = random_test_form.id
        self.form_template = test_configuration.get_form_template(
            random_test_form.usedTemplate
        )
        self.form_submission_generator = None

    def on_start(self) -> None:
        self.form_submission_generator = FormSubmissionGenerator(
            self.form_id, self.form_template
        )

        self.lambda_client = client(
            "lambda",
            region_name="ca-central-1",
            config=Config(retries={"max_attempts": 10}),
        )

    @task
    def submit_response(self) -> None:
        generated_response = self.form_submission_generator.generate_response()

        with self.parent.environment.events.request.measure(
            "task", "/forms/submit"
        ) as request_meta:
            submission = {
                "FunctionName": "Submission",
                "Payload": json.dumps(
                    {
                        "formID": self.form_id,
                        "responses": generated_response.response_data,
                        "language": "en",
                        "securityAttribute": "Protected A",
                    }
                ).encode("utf-8"),
            }

            result = self.lambda_client.invoke(**submission)

            payload = json.loads(result["Payload"].read().decode())

            if result.get("FunctionError") or not payload.get("status"):
                raise ValueError("Submission Lambda could not process form response")

            if len(generated_response.attachments) > 0:
                self.upload_submission_attachments(
                    generated_response.attachments, payload["fileURLMap"]
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
