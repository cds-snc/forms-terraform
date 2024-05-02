import logging
import json
import os
from invokust.aws_lambda import get_lambda_runtime_info
from invokust import LocustLoadTest, create_settings

logging.basicConfig(level=logging.INFO)

class LoadTest(LocustLoadTest):
    def getFormInfo(self):
        for cls in self.env.user_classes:
            cls.on_test_stop()


def handler(event=None, context=None):
    try:
        if event:
            settings = create_settings(**event)
        else:
            settings = create_settings(from_environment=True)

        if os.path.exists("/tmp/form_completion.json"):
            os.remove("/tmp/form_completion.json")

        loadtest = LoadTest(settings)
        loadtest.run()

    except Exception as e:
        logging.error("Locust exception {0}".format(repr(e)))

    else:
        loadtest.getFormInfo()
        locust_stats = loadtest.stats()
        lambda_runtime_info = get_lambda_runtime_info(context)
        loadtest_results = locust_stats.copy()
        loadtest_results.update(lambda_runtime_info)

        form_input_file = open("/tmp/form_completion.json", "r")
        form_input = json.load(form_input_file)
        loadtest_results.update({"form_input":form_input})
        json_results = json.dumps(loadtest_results)

        ### Clean up
        if os.path.exists("/tmp/form_completion.json"):
            os.remove("/tmp/form_completion.json")
        
        return json_results