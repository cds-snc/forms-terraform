from locust import HttpUser, between
from tests.behaviours.submit_client import FormSubmitThroughClientBehaviour


class SubmitThroughClientWithFileUploadUser(HttpUser):
    tasks = [FormSubmitThroughClientBehaviour]
    wait_time = between(1, 5)
    weight = 1
