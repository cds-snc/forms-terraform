#!/bin/bash

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

tgswitch 0.83.0
tfswitch 1.12.2

export TG_PROVIDER_CACHE=1



if aws s3api list-buckets | grep -q "forms-${AWS_ACCOUNT_ID}-tfstate"; then
  printf "${greenColor}=> Terraform State Bucket exists...${reset}\n"
else  

  printf "${yellowColor}=> No State to refresh.${reset}\n"
  exit 0
fi

if aws dynamodb list-tables | grep -q "tfstate-lock"; then
  printf "${greenColor}=> Terraform Lock DynamoDB table exists...${reset}\n"
else
  printf "${yellowColor}=> Terrafrom Lock tables do not exist.  Broken install need to be fixed manually.${reset}\n"
  exit 0
fi

printf "${yellowColor}=> Clearing local files...${reset}\n"
for dir in $basedir/env/cloud/*/; do
  rm -rf "${dir}.terragrunt-cache"
  rm -f "${dir}.terraform.lock.hcl"
done


if [ -z "$MODULE_NAME" ]; then
  printf "${greenColor}=> Refreshing All Terragrunt Modules${reset}\n"
  terragrunt run --all \
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
    --queue-include-dir $basedir/env/cloud/guard_duty \
    refresh
else
  printf "${greenColor}=> Only refreshing ${MODULE_NAME} Terragrunt Module${reset}\n"
  cd $basedir/env/cloud/$MODULE_NAME
  terragrunt refresh --non-interactive --log-level info
  exit 0
fi

# Print out the time it took to initialize the infrastructure


printf "${greenColor} State refreshed"

