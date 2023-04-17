#!/bin/bash

basedir=$(pwd)

(trap 'kill 0' SIGINT; DYNAMODB_SHARE_DB=1 LS_LOG=warn localstack start & (sleep 10 && $basedir/localstack_services.sh))