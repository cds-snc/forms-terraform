from dataclasses import dataclass
import random
import string
from typing import Any, Dict, List, Union
import uuid
from collections import namedtuple


Response = Union[str, List[str], int, List[Dict[str, Any]], Dict[str, Any]]
ResponseData = Dict[int, Response]
Attachment = namedtuple("Attachment", "name, size")
Attachments = Dict[str, Attachment]


@dataclass
class GeneratedResponse:
    response_data: ResponseData
    attachments: Attachments


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

    def generate_response(self) -> GeneratedResponse:
        """Generate a response based on the form template."""
        response_data: ResponseData = {}
        attachments: Attachments = {}
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
                response_data[question_id] = self.lipsum(random.randint(5, 10))
            elif question_type in ["textArea", "richText"]:
                response_data[question_id] = self.lipsum(random.randint(10, 20))
            elif question_type in [
                "dropdown",
                "radio",
                "checkbox",
                "attestation",
                "combobox",
            ]:
                choices = question["properties"]["choices"]
                response_data[question_id] = random.choice(choices)[language]
            elif question_type == "fileInput":
                generated_attachment = self.generate_random_submission_attachment()
                response_data[question_id] = generated_attachment
                attachments[generated_attachment["id"]] = Attachment(
                    generated_attachment["name"], generated_attachment["size"]
                )
            else:
                raise ValueError("Unsupported question type")

        return GeneratedResponse(response_data, attachments)

    def lipsum(self, length: int) -> str:
        """Generate a random string of lorem ipsum."""
        return " ".join(random.choices(self.lipsum_words, k=length)).capitalize()

    def generate_random_submission_attachment(self):
        id = uuid.uuid4()
        filename = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
        size_in_bytes = random.randint(
            1 * 1048576, 5 * 1048576
        )  # Between 1 MB and 5 MB
        return {"id": str(id), "name": f"{filename}.txt", "size": size_in_bytes}
