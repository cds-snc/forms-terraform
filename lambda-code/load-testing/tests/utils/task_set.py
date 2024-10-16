import os
import json

from urllib.parse import urlparse
from locust import SequentialTaskSet
from typing import Any, Dict

from utils.data_structures import PrivateApiKey


class SequentialTaskSetWithFailure(SequentialTaskSet):

    def __init__(self, parent) -> None:
        super().__init__(parent)
        parsed_url = urlparse(parent.host)
        self.api_url = f"{parsed_url.scheme}://api.{parsed_url.netloc}"
        self.idp_url = f"{parsed_url.scheme}://auth.{parsed_url.netloc}"
        self.idp_project_id = os.getenv("IDP_PROJECT_ID", "275372254274006635")
        self.private_api_key_app = PrivateApiKey.from_json(
            json.loads(os.getenv("PRIVATE_API_KEY_APP_JSON"))
        )
        self.private_api_key_form = PrivateApiKey.from_json(
            json.loads(os.getenv("PRIVATE_API_KEY_FORM_JSON"))
        )

    def request_with_failure_check(
        self, method: str, url: str, status_code: int, **kwargs: Dict[str, Any]
    ) -> dict:
        kwargs["catch_response"] = True
        with self.client.request(method, url, **kwargs) as response:
            if response.status_code != status_code:
                response.failure(
                    f"Request failed: {response.status_code} {response.text}"
                )
                raise ValueError(
                    f"Request failed: {response.status_code} {response.text}"
                )
            return (
                response.json()
                if "application/json" in response.headers.get("Content-Type", "")
                else response.text
            )
