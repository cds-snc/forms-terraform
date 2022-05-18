#!/bin/bash

printf "Configuring localstack components via terraform..."

basedir=$(pwd)

export TF_VAR_localstack_host="localstack"

printf "Setting up local KMS..."
cd $basedir/env/local/kms
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating SQS queue..."
cd $basedir/env/local/sqs
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating SNS queue..."
cd $basedir/env/local/sns
rm -rf .terragrunt-cache
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating the DynamoDB database..."
cd $basedir/env/local/dynamodb
rm -rf .terragrunt-cache
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Creating the S3 buckets..."
cd $basedir/env/local/app
terragrunt apply --terragrunt-non-interactive -auto-approve

printf "Installing lambda dependencies..."
cd $basedir/aws/app/lambda
find . -maxdepth 3 -name package.json -execdir yarn install \;