#!/bin/bash

find . -maxdepth 3 -name package.json -execdir yarn install \;

# Check if running locally or in the devcontainer
if [[ -z "${DEVCONTAINER}" ]]; then
  sam local start-lambda -t ./local_development/template.yml \
    --host 0.0.0.0 \
    --port 3001 \
    --warm-containers EAGER
else
  # devcontainer detected: set the container host and resolve the IP of the docker host
  HOST_IP="$(dig +short host.docker.internal)"
  sam local start-lambda -t ./local_development/template.yml \
    --host 0.0.0.0 \
    --port 3001 \
    --warm-containers EAGER \
    --parameter-overrides "ParameterKey=DBHost,ParameterValue=$HOST_IP"
fi
