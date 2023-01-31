#!/bin/bash

export TF_VAR_cognito_client_id=""
export TF_VAR_cognito_endpoint_url=""
export TF_VAR_cognito_user_pool_arn=""
export TF_VAR_email_address_contact_us=""
export TF_VAR_email_address_support=""


basedir=$(pwd)

ACTION=$1

printf "Configuring localstack components via terraform...\n"

if [["${ACTION}" = "clean"]]; then
  printf "=> Cleaning up previous caches, terraform state, and lambda dependencies\n"

  printf "...Purging stale localstack related files\n"
  find $basedir/env/local -type d -name .terragrunt-cache -prune -exec rm -rf {} \;

  printf "...Removing old lambda dependencies\n"
    cd $basedir/aws/app/lambda
    ./deps.sh delete
fi

printf "=> Cleaning previous terrafrom state, keeping previous terraform packages and lambda dependencies\n"

printf "...Purging stale terraform state files\n"
  find $basedir/env/local -type d -name terraform.tfstate -prune -exec rm -rf {} \;

printf "=> Creating AWS services in Localstack\n"

printf "...Setting up local KMS\n"
cd $basedir/env/local/kms
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "...Creating SQS queue\n"
cd $basedir/env/local/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "...Creating SNS queue\n"
cd $basedir/env/local/sns
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "...Creating the DynamoDB database\n"
cd $basedir/env/local/dynamodb
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "...Installing lambda dependencies\n"
cd $basedir/aws/app/lambda
./deps.sh install

printf "...Creating the S3 buckets...\n"
cd $basedir/env/local/app
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "=> Starting Lambdas\n"
cd $basedir/aws/app/lambda
sam local start-lambda -t "./local_development/template.yml" \
  --host 127.0.0.1 \
  --port 3001 \
  --warm-containers EAGER