import global_setup  # This line ensures global setup runs before the test and creates the test_configuration file in /tmp
from locust import HttpUser, between
from behaviours.api import RetrieveResponseBehaviour
from behaviours.idp import AccessTokenBehaviour
from tests.behaviours.submit_infra import FormSubmitThroughInfraBehaviour
from utils.http2_user import Http2User


class ApiUser(HttpUser):
    tasks = [RetrieveResponseBehaviour]
    wait_time = between(1, 5)
    weight = 6


class FormSubmitUser(HttpUser):
    tasks = [FormSubmitThroughInfraBehaviour]
    wait_time = between(1, 5)
    weight = 2


class IdpUser(Http2User):
    tasks = [AccessTokenBehaviour]
    wait_time = between(1, 5)
    weight = 1
