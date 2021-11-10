#!/bin/bash
#
# Lambda helper script to install or delete the dependencies.
# Use: deps.sh [install|delete]
#
set -euo pipefail
IFS=$'\n\t'

ACTION=$1
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if [ "$ACTION" = "delete" ]; then
    find "$SCRIPT_DIR/load_testing" -mindepth 1 -maxdepth 1 -type d -exec rm -rvf {} +
else
    apt update && apt install -y python3-testresources
    pip3 install -r "$SCRIPT_DIR/load_testing/requirements.txt" --target "$SCRIPT_DIR/load_testing"
fi
