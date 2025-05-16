#!/bin/bash
#
# Lambda helper script to install or delete the dependencies. 
# Use: deps.sh [install|delete]
#
set -euo pipefail
IFS=$'\n\t'

ACTION=$1
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Loop over the Lambda directories
for LAMBDA_DIR in "$SCRIPT_DIR"/*/; do
    if test -f "$LAMBDA_DIR/package.json"; then
        echo "⚡ $LAMBDA_DIR $ACTION"
        if [ "$ACTION" = "delete" ]; then
            rm -rf "$LAMBDA_DIR/node_modules"
            rm -rf "$LAMBDA_DIR/build" || true
        else
            (cd "$LAMBDA_DIR" && yarn install)
            if test -f "$LAMBDA_DIR/tsconfig.json"; then
                echo "⚡ $LAMBDA_DIR Building TypeScript"
                (cd "$LAMBDA_DIR" && yarn build)
            fi      
        fi
    fi
done
