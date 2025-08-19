import invokust
import logging
import os
import boto3
import json

from invokust.aws_lambda import get_lambda_runtime_info

logging.basicConfig(level=logging.INFO)

ssm_client = boto3.client("ssm")


def get_ssm_parameters(client, parameter_names):
    response = client.get_parameters(Names=parameter_names, WithDecryption=True)
    return {param["Name"]: param["Value"] for param in response["Parameters"]}


# Load required environment variables from AWS SSM
params = get_ssm_parameters(
    ssm_client,
    [
        "/load-testing/zitadel-app-private-key",
    ],
)

os.environ["ZITADEL_APP_PRIVATE_KEY"] = params["/load-testing/zitadel-app-private-key"]


def handler(event: dict[str, any], context=None):

    # Check for required environment variables
    required_env_vars = [
        "ZITADEL_APP_PRIVATE_KEY",
    ]

    for env_var in required_env_vars:
        if env_var not in os.environ:
            raise ValueError(f"Missing required environment variable: {env_var}")

    try:
        test_configuration = event.pop("testConfiguration")
        thread_id = event.pop("thread_id")

        os.environ["THREAD_ID"] = thread_id

        with open("/tmp/test_configuration.json", "w") as file:
            json.dump(test_configuration, file)

        loadtest = invokust.LocustLoadTest(invokust.create_settings(**event))
        loadtest.run()
    except Exception as e:
        logging.error("Exception running locust tests {0}".format(repr(e)))
    else:
        locust_stats = loadtest.stats()
        lambda_runtime_info = get_lambda_runtime_info(context)
        loadtest_results = locust_stats.copy()
        loadtest_results.update(lambda_runtime_info)
        return json.dumps(loadtest_results)
