#!/bin/bash
set -eo pipefail

SCRIPT_DIR="$(dirname $(readlink -f $0))"

# Check if a given process is actively running
function pgrep_live {
  PIDS=$(pgrep "$1");
  [ "$PIDS" ] || return;
  ps -o s= -o pid= $PIDS | sed -n 's/^[^ZT][[:space:]]\+//p';
}

# Install yarn dependencies
find "$SCRIPT_DIR" -maxdepth 3 -name package.json -execdir yarn install \;

# Devcontainer specific startup commands
if [[ -n "${DEVCONTAINER}" ]]; then

  # Start the Docker-in-Docker helper in the bacgkround if it's not already running
  if [[ "$(pgrep_live 'dind_add_host')" = "" ]]; then
    echo "⚡ Starting Docker-in-Docker add host helper"
    nohup bash -c '/workspace/.devcontainer/scripts/dind_add_host.sh &' >/dev/null 2>&1
  fi

fi

# Start the lambda functions
sam local start-lambda -t "$SCRIPT_DIR/local_development/template.yml" \
  --host 0.0.0.0 \
  --port 3001 \
  --warm-containers EAGER
