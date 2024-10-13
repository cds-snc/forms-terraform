from locust import HttpUser, between

from behaviours.api import RetrieveResponseBehaviour
from behaviours.idp import AccessTokenBehaviour
from behaviours.submit import FormSubmitBehaviour


class ApiUser(HttpUser):
    tasks = [RetrieveResponseBehaviour]
    wait_time = between(1, 5)
    weight = 6


class FormSubmitUser(HttpUser):
    tasks = [FormSubmitBehaviour]
    wait_time = between(1, 5)
    weight = 3


class IdpUser(HttpUser):
    tasks = [AccessTokenBehaviour]
    wait_time = between(1, 5)
    weight = 1
