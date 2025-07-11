from locust import SequentialTaskSet
from typing import Any, Dict


class SequentialTaskSetWithFailure(SequentialTaskSet):

    def __init__(self, parent) -> None:
        super().__init__(parent)

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
