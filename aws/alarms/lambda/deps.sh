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
        else
            yarn --cwd "$LAMBDA_DIR" install
            if test -f "$LAMBDA_DIR/tsconfig.json"; then
                echo "⚡ $LAMBDA_DIR Building TypeScript"
                yarn --cwd "$LAMBDA_DIR" build      
            fi      
        fi
    fi
done