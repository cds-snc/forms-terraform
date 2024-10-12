import os
import json
import random
from typing import Any, Dict, List, Union
from botocore.config import Config
from boto3 import client

Response = Union[str, List[str], int, List[Dict[str, Any]], Dict[str, Any]]
SubmissionRequestBody = Dict[int, Response]

AWS_REGION=os.getenv("AWS_REGION", "ca-central-1")


class FormSubmissionGenerator:
    """Generate and submit form responses to the Submission Lambda function."""

    form_id: str = None
    form_template: Dict[str, Any] = None
    lambda_client = None

    def __init__(self, form_id: str, form_template: Dict[str, Any]) -> None:
        self.form_id = form_id
        self.form_template = form_template
        self.lambda_client = client('lambda', region_name=AWS_REGION, config=Config(retries={'max_attempts': 10}))

    def generate_response(self) -> SubmissionRequestBody:
        """Generate a response based on the form template."""
        response: SubmissionRequestBody = {}
        language: str = random.choice(["en", "fr"])

        # For each question in the form template, generate a random response
        for question_id in self.form_template["layout"]:
            question = next((elem for elem in self.form_template["elements"] if elem["id"] == question_id), None)
            if not question:
                raise ValueError("Could not find question in form template")
            
            question_type: str = question["type"]
            if question_type == "textField":
                response[question_id] = "Test response" if language == "en" else "Réponse de test"
            elif question_type in ["textArea", "richText"]:
                response[question_id] = (
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse ac metus sed odio rutrum eleifend. "
                    "Donec eu viverra nisl. Duis sit amet accumsan lacus. Nunc eleifend justo nunc. Vestibulum vitae lectus "
                    "nisl. Aenean ullamcorper dictum arcu, quis sagittis arcu bibendum non."
                )
            elif question_type in ["dropdown", "radio", "checkbox", "attestation", "combobox"]:
                choices = question["properties"]["choices"]
                response[question_id] = random.choice(choices)[language]
            else:
                raise ValueError("Unsupported question type")

        return response
    
    def submit_response(self) -> None:
        """Submit a response to the Lambda Submission function."""
        submission = {
            "FunctionName": "Submission",
            "Payload": json.dumps({
                "formID": self.form_id,
                "responses": self.generate_response(),
                "language": "en",
                "securityAttribute": "Protected A"
            }).encode('utf-8')
        }
        result = self.lambda_client.invoke(**submission)
        payload = json.loads(result['Payload'].read().decode())
        if result.get("FunctionError") or not payload.get("status"):
            raise ValueError("Submission Lambda could not process form response")



