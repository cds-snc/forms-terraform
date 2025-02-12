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

if aws s3api list-buckets | grep -q "forms-development-tfstate"; then
  printf "${yellowColor}=> Terraform State Bucket exists...${reset}\n"
else
  printf "${yellowColor}=> Detected fresh AWS account instance.  Setting up backend S3...${reset}\n"
  # create S3 bucket for Terraform state files
  aws s3api create-bucket \
    --bucket forms-development-tfstate \
    --region ca-central-1 \
    --create-bucket-configuration LocationConstraint=ca-central-1
    # encrypt the bucket
  aws s3api put-bucket-encryption \
    --bucket forms-development-tfstate \
    --server-side-encryption-configuration "{\"Rules\": [{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\": \"AES256\"}}]}"
fi

if aws dynamodb list-tables | grep -q "tfstate-lock"; then
  printf "${yellowColor}=> Terraform Lock DynamoDB table exists...${reset}\n"
else
  printf "${yellowColor}=> Detected fresh AWS account instance.  Setting up Terraform Lock table...${reset}\n"
  # create DynamoDB table for Terraform state locking
  aws dynamodb create-table \
    --table-name tfstate-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

  printf "${yellowColor}=> Detected fresh Localstack instance! Cleaning up Terragrunt caches and Terraform state files...${reset}\n"

  for dir in $basedir/env/cloud/*/; do
    rm -rf "${dir}.terragrunt-cache"
    rm -f "${dir}.terraform.lock.hcl"
  done
fi

printf "${greenColor}=> Destroying AWS services${reset}\n"

printf "${greenColor}...Destroying VPN${reset}\n"
cd $basedir/env/cloud/vpn
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



# printf "${color}...Building and pushing Lambda images${reset}\n"
# cd $basedir/lambda-code
# ./deps.sh install
# ./deploy-lambda-images.sh

# printf "${greenColor}...Destroying Lambdas${reset}\n"
# cd $basedir/env/cloud/lambdas
# terragrunt apply --terragrunt-non-interactive -auto-approve --terragrunt-log-level warn

printf "${greenColor}All infratructure destroyed${reset}\n"