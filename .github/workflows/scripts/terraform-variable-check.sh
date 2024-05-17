#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#
# This script checks that all the GitHub workflow Terraform variables defined as `TF_VAR_` prefixed
# environment variables have a matching `variable` definition in the codebase.  This is being done
# to prevent accidental mismatches between the GitHub workflow and the Terraform codebase. 
#


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKFLOW_VARS="$(grep -r "^\s*TF_VAR" $SCRIPT_DIR/../ | awk -F ':' '{print $2}' | sort | uniq | sed 's/^[[:blank:]]*TF_VAR_//')"

# Loop through all the variables in the workflow and check if they are defined in the *.tf code
for VAR in $WORKFLOW_VARS; do
    echo "🔎 Checking variable: \"$VAR\""
    grep -r "variable \"$VAR\"" "$SCRIPT_DIR/../../../" || (echo "❌ Variable \"$VAR\" is not defined as a Terraform variable" && exit 1)
done
