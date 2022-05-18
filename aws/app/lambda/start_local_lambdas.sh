#!/bin/bash

# Check if running locally or in the devcontainer
if [[ -z "${DEVCONTAINER}" ]]; then
  find . -maxdepth 3 -name package.json -execdir yarn install \;
fi

sam local start-lambda -t ./local_development/template.yml --host 0.0.0.0 --port 3001 --warm-containers EAGER