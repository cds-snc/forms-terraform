#!/bin/bash

find . -maxdepth 3 -name package.json -execdir yarn install \;

# Check if running locally or in the devcontainer
if [[ -z "${DEVCONTAINER}" ]]; then
  sam local start-lambda -t ./local_development/template.yml --host 0.0.0.0 --port 3001 --warm-containers EAGER
else
  # devcontainer detected, set container host to host.docker.internal
  sam local start-lambda -t ./local_development/template.yml --host 0.0.0.0 --port 3001 --warm-containers EAGER --container-host host.docker.internal
fi
