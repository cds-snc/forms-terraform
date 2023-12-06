#!/bin/bash

export TF_VAR_cognito_client_id=""
export TF_VAR_cognito_endpoint_url=""
export TF_VAR_cognito_user_pool_arn=""
export TF_VAR_email_address_contact_us=""
export TF_VAR_email_address_support=""
export APP_ENV="local"

# Exit on any error
set -e

# Text colors
color='\033[1;95m' 
reset='\033[0m' # No Color

# Set proper terraform and terragrunt versions

tgswitch 0.53.2
tfswitch 1.6.4

# Usage:
# Without any args will reuse the existing cached packages saving some time and bandwidth
# With the 'clean' argument will remove all cached packages for terraform and node modules for lambdas.

basedir=$(pwd)

ACTION=$1

if [[ "${ACTION}" == "clean" ]]; then

  printf "${color}=> Cleaning up previous caches, terraform state, and lambda dependencies${reset}\n"

  printf "${color}...Purging stale localstack related files${reset}\n"
  find $basedir/env -type d -name .terragrunt-cache -prune -print -exec rm -rf {} \;
  
  printf "${color}...Purging stale terraform state files${reset}\n"
  find $basedir/env -type f -name terraform.tfstate -prune -exec rm -fv {} \;

  printf "${color}...Removing old lambda dependencies${reset}\n"
  cd $basedir/aws/lambdas/code
  ./deps.sh delete

fi

printf "${color}=> Creating AWS services in Localstack${reset}\n"

printf "${color}...Setting up KMS${reset}\n"
cd $basedir/env/cloud/kms
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Setting up Secrets Manager${reset}\n"
cd $basedir/env/cloud/secrets
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Setting up S3${reset}\n"
cd $basedir/env/cloud/s3
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Creating SQS queue${reset}\n"
cd $basedir/env/cloud/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Creating SNS queue${reset}\n"
cd $basedir/env/cloud/sns
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Creating the DynamoDB database${reset}\n"
cd $basedir/env/cloud/dynamodb
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}...Installing lambda dependencies${reset}\n"
cd $basedir/aws/lambdas/code
./deps.sh install

printf "${color}...Clearing old archive files${reset}\n"
rm -v /tmp/*.zip || true

printf "${color}...Creating lambdas${reset}\n"
cd $basedir/env/cloud/lambdas
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${color}All infratructure initialized:  Ready for requests${reset}\n"
