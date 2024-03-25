#!/bin/bash

# Text colors
color='\033[1;95m' 
reset='\033[0m' # No Color

if test -f .env
then
  set -o allexport
  source .env
  set +o allexport
  printf "${color}=> Environment variables loaded from .env${reset}\n"
else
  # In case developers have not set up their .env file (can be removed in the future)
  export APP_ENV="local"
fi

# Exit on any error
set -e

# Set proper terraform and terragrunt versions

tgswitch 0.54.8
tfswitch 1.6.6

basedir=$(pwd)

ACTION=$1

if [[ "${ACTION}" == "clean" ]]
then
  printf "${color}=> Cleaning up previous caches, terraform state, and lambda dependencies${reset}\n"

  printf "${color}...Purging stale localstack related files${reset}\n"
  find $basedir/env/cloud -type d -name .terragrunt-cache -prune -print -exec rm -rf {} \;

  printf "${color}...Purging stale terraform state files${reset}\n"
  find $basedir/env -type f -name terraform.tfstate -prune -exec rm -fv {} \;

  printf "${color}...Clearing old lambda_code archive files${reset}\n"
  rm -v /tmp/*.zip || true

  printf "${color}...Removing old lambda dependencies${reset}\n"
  cd $basedir/aws/lambdas/code
  ./deps.sh delete
fi

printf "${color}=> Creating AWS services in Localstack${reset}\n"

printf "${color}...Setting up KMS${reset}\n"
cd $basedir/env/cloud/kms
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Setting up Network${reset}\n"
cd $basedir/env/cloud/network
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Setting up Secrets Manager${reset}\n"
cd $basedir/env/cloud/secrets
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Creating SQS queue${reset}\n"
cd $basedir/env/cloud/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Creating SNS queue${reset}\n"
cd $basedir/env/cloud/sns
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Setting up Redis${reset}\n"
cd $basedir/env/cloud/redis
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Setting up RDS${reset}\n"
cd $basedir/env/cloud/rds
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Setting up S3${reset}\n"
cd $basedir/env/cloud/s3
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Creating the DynamoDB database${reset}\n"
cd $basedir/env/cloud/dynamodb
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Installing lambda dependencies${reset}\n"
cd $basedir/aws/lambdas/code
./deps.sh install

printf "${color}...Creating lambdas${reset}\n"
cd $basedir/env/cloud/lambdas
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}All infratructure initialized:  Ready for requests${reset}\n"