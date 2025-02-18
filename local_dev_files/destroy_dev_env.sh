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
  export APP_ENV="development"
fi

# Set proper terraform and terragrunt versions

tgswitch 0.72.5
tfswitch 1.10.5

basedir=$(pwd)

printf "${greenColor}=> Destroying AWS services${reset}\n"

printf "${greenColor}...Destroying VPN${reset}\n"
cd $basedir/env/cloud/vpn
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying Lambdas${reset}\n"
cd $basedir/env/cloud/lambdas
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying ECR${reset}\n"
cd $basedir/env/cloud/ecr
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying DynamoDB${reset}\n"
cd $basedir/env/cloud/dynamodb
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying S3${reset}\n"
cd $basedir/env/cloud/s3
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying RDS${reset}\n"
cd $basedir/env/cloud/rds
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying Redis${reset}\n"
cd $basedir/env/cloud/redis
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Creating SNS queue${reset}\n"
cd $basedir/env/cloud/sns
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Creating SQS queue${reset}\n"
cd $basedir/env/cloud/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying Secrets Manager${reset}\n"
cd $basedir/env/cloud/secrets
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying Network${reset}\n"
cd $basedir/env/cloud/network
# terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn 
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl

printf "${greenColor}...Destroying KMS${reset}\n"
cd $basedir/env/cloud/kms
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn --terragrunt-config destroy_terragrunt.hcl



printf "${greenColor}All infratructure destroyed${reset}\n"