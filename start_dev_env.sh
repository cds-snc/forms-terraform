#!/bin/bash

basedir=$(pwd)

(trap 'kill -9' SIGINT; (sleep 10 && $basedir/localstack_services.sh) & DYNAMODB_SHARE_DB=1 LAMBDA_RUNTIME_ENVIRONMENT_TIMEOUT=60 LS_LOG=warn localstack start)
