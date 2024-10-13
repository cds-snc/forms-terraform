import logging
from invokust.aws_lambda import get_lambda_runtime_info
from invokust import LocustLoadTest, create_settings

logging.basicConfig(level=logging.INFO)


def handler(event=None, context=None):
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
