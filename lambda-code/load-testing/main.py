import logging
import os
import boto3
from invokust.aws_lambda import get_lambda_runtime_info
from invokust import LocustLoadTest, create_settings

logging.basicConfig(level=logging.INFO)

ssm_client = boto3.client("ssm")


def get_ssm_parameter(client, parameter_name):
    response = client.get_parameter(Name=parameter_name, WithDecryption=True)
    return response["Parameter"]["Value"]

# Load required environment variables from AWS SSM
os.environ["FORM_ID"] = get_ssm_parameter(ssm_client, "load-testing/form-id")
os.environ["PRIVATE_API_KEY_APP_JSON"] = get_ssm_parameter(
    ssm_client, "load-testing/private-api-key-app"
)
os.environ["PRIVATE_API_KEY_USER_JSON"] = get_ssm_parameter(
    ssm_client, "load-testing/private-api-key-user"
)


def handler(event=None, context=None):

    # Check for required environment variables
    required_env_vars = [
        "FORM_ID",
        "PRIVATE_API_KEY_APP_JSON",
        "PRIVATE_API_KEY_USER_JSON",
    ]
    for env_var in required_env_vars:
        if env_var not in os.environ:
            raise ValueError(f"Missing required environment variable: {env_var}")

    try:
        settings = (
            create_settings(**event)
            if event
            else create_settings(from_environment=True)
        )
        loadtest = LocustLoadTest(settings)
        loadtest.run()
    except Exception as e:
        logging.error("Exception running locust tests {0}".format(repr(e)))
    else:
        locust_stats = loadtest.stats()
        locust_stats.update(get_lambda_runtime_info(context))
        return locust_stats
