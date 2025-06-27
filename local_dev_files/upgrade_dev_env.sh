#!/bin/bash
SECONDS=0
# Exit on any error
set -e

MODULE_NAME=$1

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color
basedir=$(pwd)

# Set proper terraform and terragrunt versions

tgswitch 0.81.10
tfswitch 1.12.2

export TG_PROVIDER_CACHE=1

if aws s3api list-buckets | grep -q "forms-${AWS_ACCOUNT_ID}-tfstate"; then
    printf "${yellowColor}=> Terraform State Bucket exists...${reset}\n"
else

    printf "${yellowColor}=> Terraform State Bucket does not exist...${reset}\n"
    printf "${yellowColor}=> No need to upgrade, just run 'make build_env'${reset}\n"
    exit 0
fi

if [ -z "$MODULE_NAME" ]; then
    printf "${greenColor}=> Building All Terragrunt Modules${reset}\n"
    terragrunt run-all init --upgrade \
        --non-interactive --log-level info --queue-strict-include \
        --working-dir $basedir/env \
        --queue-include-dir $basedir/env/cloud/kms \
        --queue-include-dir $basedir/env/cloud/network \
        --queue-include-dir $basedir/env/cloud/secrets \
        --queue-include-dir $basedir/env/cloud/sqs \
        --queue-include-dir $basedir/env/cloud/s3 \
        --queue-include-dir $basedir/env/cloud/ecr \
        --queue-include-dir $basedir/env/cloud/sns \
        --queue-include-dir $basedir/env/cloud/redis \
        --queue-include-dir $basedir/env/cloud/rds \
        --queue-include-dir $basedir/env/cloud/dynamodb \
        --queue-include-dir $basedir/env/cloud/lambdas \
        --queue-include-dir $basedir/env/cloud/vpn \
        --queue-include-dir $basedir/env/cloud/guard_duty
else
    printf "${greenColor}=> Only building ${MODULE_NAME} Terragrunt Module${reset}\n"
    cd $basedir/env/cloud/$MODULE_NAME
    terragrunt apply --non-interactive --log-level info -auto-approve
    exit 0
fi

# Print out the time it took to initialize the infrastructure

t=$SECONDS
printf "${greenColor}Infrastructure modules updated to new provider version specified${reset}\n" "$((t / 60 - 1440 * (t / 86400)))"
