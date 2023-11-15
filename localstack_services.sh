#!/bin/bash

export TF_VAR_cognito_client_id=""
export TF_VAR_cognito_endpoint_url=""
export TF_VAR_cognito_user_pool_arn=""
export TF_VAR_email_address_contact_us=""
export TF_VAR_email_address_support=""
export APP_ENV="local"

# Set proper terraform and terragrunt versions

tgswitch 0.53.2
tfswitch 1.4.2

# Usage:
# Without any args will reuse the existing cached packages saving some tiem and bandwidth
# With the 'clean' argument will remove all cached packages for terraform and node modules for lambdas.

basedir=$(pwd)

ACTION=$1

printf "Configuring localstack components via terraform...\n"

if [[ "${ACTION}" == "clean" ]]; then
  printf "=> Cleaning up previous caches, terraform state, and lambda dependencies\n"

  printf "...Purging stale terraform state files\n"
  find $basedir/env -type f -name terraform.tfstate -prune -exec rm -fv {} \;

  printf "...Purging stale localstack related files\n"
  find $basedir/env -type d -name .terragrunt-cache -prune -exec rm -rf {} \;

  printf "...Removing old lambda dependencies\n"
    cd $basedir/aws/lambdas/code
    ./deps.sh delete
fi

printf "=> Creating AWS services in Localstack\n"

printf "...Setting up local KMS\n"
cd $basedir/env/cloud/kms
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "...Setting up local Secrets Manager\n"
cd $basedir/env/cloud/secrets
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "...Creating SQS queue\n"
cd $basedir/env/cloud/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "...Creating SNS queue\n"
cd $basedir/env/cloud/sns
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "...Creating the DynamoDB database\n"
cd $basedir/env/cloud/dynamodb
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "...Installing lambda dependencies\n"
cd $basedir/aws/lambdas/code
./deps.sh install

printf "...Creating lambdas\n"
cd $basedir/env/cloud/lambdas
terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn
