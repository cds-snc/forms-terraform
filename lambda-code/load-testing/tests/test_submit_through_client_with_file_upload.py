import global_setup  # This line ensures global setup runs before the test and creates the test_configuration file in /tmp
from locust import HttpUser, between
from behaviours.submit_client import FormSubmitThroughClientBehaviour


class SubmitThroughClientWithFileUploadUser(HttpUser):
    tasks = [FormSubmitThroughClientBehaviour]
    wait_time = between(1, 5)
    weight = 1
