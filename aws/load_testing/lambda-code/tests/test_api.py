import global_setup  # This line ensures global setup runs before the test and creates the test_configuration file in /tmp
from locust import HttpUser
from behaviours.api import RetrieveResponseBehaviour


class ApiUser(HttpUser):
    tasks = [RetrieveResponseBehaviour]
