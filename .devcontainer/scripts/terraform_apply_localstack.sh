#!/bin/bash

export TF_VAR_localstack_host="localstack"
basedir=$(pwd)

printf "Configuring localstack components via terraform...\n"

printf "Purging stale localstack related files\n"
find $basedir/env/local -type d -name .terragrunt-cache -prune -exec rm -rf {} \;
rm -rf $basedir/.devcontainer/data/data

printf "Setting up local KMS...\n"
cd $basedir/env/local/kms
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating SQS queue...\n"
cd $basedir/env/local/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating SNS queue...\n"
cd $basedir/env/local/sns
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating the DynamoDB database...\n"
cd $basedir/env/local/dynamodb
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating the S3 buckets...\n"
cd $basedir/env/local/app
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Installing lambda dependencies...\n"
cd $basedir/aws/app/lambda
find . -maxdepth 3 -name package.json -execdir yarn install \;
