#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname $(readlink -f $0))"

# Install yarn dependencies
find "$SCRIPT_DIR" -maxdepth 3 -name package.json -execdir yarn install \;

# Start the Docker-in-Docker helper for the devcontainer
if ! pgrep "dind_add_host" > /dev/null; then
  echo "⚡ Start Docker-in-Docker add host"
  nohup bash -c '/workspace/.devcontainer/scripts/dind_add_host.sh &' >/dev/null 2>&1
fi

# Start the lambda functions
sam local start-lambda -t "$SCRIPT_DIR/local_development/template.yml" \
  --host 0.0.0.0 \
  --port 3001 \
  --warm-containers EAGER
