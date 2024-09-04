#!/bin/bash

# Exit on any error
set -e

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color

if test -f .env
then
  set -o allexport
  source .env
  set +o allexport
  printf "${greenColor}=> Environment variables loaded from .env${reset}\n"
else
  # In case developers have not set up their .env file (can be removed in the future)
  export APP_ENV="local"
fi

# Set proper terraform and terragrunt versions

tgswitch 0.63.2
tfswitch 1.9.2

basedir=$(pwd)

if ! curl http://localhost.localstack.cloud:4566/_localstack/health > /dev/null 2>&1; then
  printf "${redColor}=> Your Localstack instance appears to be offline. Use 'docker-compose up' to launch it.${reset}\n"
  exit 1
fi

if ! command -v awslocal > /dev/null; then
  printf "${redColor}=> This script requires 'awslocal' to be installed. See 'Prerequisites' section in the README file.${reset}\n"
  exit 1
fi

if awslocal kms list-keys | grep -q "KeyArn"; then
  printf "${yellowColor}=> Detected old Localstack instance. Will use existing Terraform state files to update resources...${reset}\n"
else
  printf "${yellowColor}=> Detected fresh Localstack instance! Cleaning up Terragrunt caches and Terraform state files...${reset}\n"

  for dir in $basedir/env/cloud/*/; do
    rm -rf $dir/.terragrunt-cache
    rm -f $dir/terraform.tfstate
    rm -f $dir/terraform.tfstate.backup
  done
fi

printf "${greenColor}=> Creating AWS services in Localstack${reset}\n"

printf "${greenColor}...Setting up KMS${reset}\n"
cd $basedir/env/cloud/kms
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Setting up Network${reset}\n"
cd $basedir/env/cloud/network
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Setting up Secrets Manager${reset}\n"
cd $basedir/env/cloud/secrets
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Creating SQS queue${reset}\n"
cd $basedir/env/cloud/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Creating SNS queue${reset}\n"
cd $basedir/env/cloud/sns
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Setting up Redis${reset}\n"
cd $basedir/env/cloud/redis
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Setting up RDS${reset}\n"
cd $basedir/env/cloud/rds
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Setting up S3${reset}\n"
cd $basedir/env/cloud/s3
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Setting up DynamoDB${reset}\n"
cd $basedir/env/cloud/dynamodb
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}...Setting up ECR${reset}\n"
cd $basedir/env/cloud/ecr
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Building and pushing Lambda images${reset}\n"
cd $basedir/lambda-code
./deps.sh install
./deploy-lambda-images.sh

printf "${greenColor}...Setting up Lambdas${reset}\n"
cd $basedir/env/cloud/lambdas
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}All infratructure initialized: Ready for requests${reset}\n"