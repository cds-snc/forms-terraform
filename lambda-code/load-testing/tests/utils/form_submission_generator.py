import os
import random
import base64
import string
from typing import Any, Dict, List, Union


Response = Union[str, List[str], int, List[Dict[str, Any]], Dict[str, Any]]
SubmissionRequestBody = Dict[int, Response]


class FormSubmissionGenerator:
    """Generate and submit form responses to the Submission Lambda function."""

    form_id: str = None
    form_template: Dict[str, Any] = None
    lambda_client = None
    lipsum_words = (
        "adipisci aliquam amet consectetur dolor dolore dolorem eius est et"
        "incidunt ipsum labore lorem magnam modi neque non numquam porro quaerat qui"
        "quia quisquam sed sit tempora ut velit voluptatem"
    ).split()

    def __init__(self, form_id: str, form_template: Dict[str, Any]) -> None:
        self.form_id = form_id
        self.form_template = form_template

    def generate_response(self) -> SubmissionRequestBody:
        """Generate a response based on the form template."""
        response: SubmissionRequestBody = {}
        language: str = random.choice(["en", "fr"])

        # For each question in the form template, generate a random response
        for question_id in self.form_template["layout"]:
            question = next(
                (
                    elem
                    for elem in self.form_template["elements"]
                    if elem["id"] == question_id
                ),
                None,
            )
            if not question:
                raise ValueError("Could not find question in form template")

            question_type: str = question["type"]
            if question_type == "textField":
                response[question_id] = self.lipsum(random.randint(5, 10))
            elif question_type in ["textArea", "richText"]:
                response[question_id] = self.lipsum(random.randint(10, 20))
            elif question_type in [
                "dropdown",
                "radio",
                "checkbox",
                "attestation",
                "combobox",
            ]:
                choices = question["properties"]["choices"]
                response[question_id] = random.choice(choices)[language]
            elif question_type == "fileInput":
                response[question_id] = self.generate_random_submission_attachment()
            else:
                raise ValueError("Unsupported question type")

        return response

    def lipsum(self, length: int) -> str:
        """Generate a random string of lorem ipsum."""
        return " ".join(random.choices(self.lipsum_words, k=length)).capitalize()

    def generate_random_submission_attachment(self):
        size_in_bytes = random.randint(
            1048576, 2097152
        )  # 1 MB to 2 MB. Encoding it in Base64 will increase each file size by 33%.
        filename = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
        raw_bytes = os.urandom(size_in_bytes)
        encoded_content = base64.b64encode(raw_bytes).decode("utf-8")

        return {
            "name": f"{filename}.txt",
            "size": size_in_bytes,
            "based64EncodedFile": encoded_content,
        }
