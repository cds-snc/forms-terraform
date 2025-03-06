#!/bin/bash

PROFILE=${1:-development}

if aws --profile "$PROFILE" sts get-caller-identity >/dev/null 2>&1; then
    echo "Valid session"
else
    echo "Invalid session: logging using SSO"
    aws sso login --profile "$PROFILE"
fi
