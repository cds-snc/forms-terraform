from locust import events
import os
import shutil
from pathlib import Path

base_dir = os.path.dirname(__file__)
test_configuration_file_path = os.path.join(base_dir, "..", "test_configuration.json")
local_tmp_test_configuration_file_path = "/tmp/test_configuration.json"


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    if is_running_locally():
        shutil.copy(
            test_configuration_file_path, local_tmp_test_configuration_file_path
        )


def is_running_locally() -> bool:
    if Path(test_configuration_file_path).exists():
        return True
    else:
        return False
