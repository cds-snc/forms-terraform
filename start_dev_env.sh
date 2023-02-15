#!/bin/bash

basedir=$(pwd)

(trap 'kill 0' SIGINT; localstack start & (sleep 10 && $basedir/localstack_services.sh))