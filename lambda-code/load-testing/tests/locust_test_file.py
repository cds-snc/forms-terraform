from locust import HttpUser, between

from behaviours.api import RetrieveResponseBehaviour
from behaviours.idp import AccessTokenBehaviour
from behaviours.submit import FormSubmitBehaviour
from utils.http2_user import Http2User


class ApiUser(HttpUser):
    tasks = [RetrieveResponseBehaviour]
    wait_time = between(1, 5)
    weight = 6


class FormSubmitUser(HttpUser):
    tasks = [FormSubmitBehaviour]
    wait_time = between(1, 5)
    weight = 2


class IdpUser(Http2User):
    tasks = [AccessTokenBehaviour]
    wait_time = between(1, 5)
    weight = 1
