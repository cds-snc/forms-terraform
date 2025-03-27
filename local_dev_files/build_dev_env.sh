#!/bin/bash
SECONDS=0
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

tgswitch 0.75.10
tfswitch 1.11.2

export TG_PROVIDER_CACHE=1

fresh_instance=false

if aws s3api list-buckets | grep -q "forms-${AWS_ACCOUNT_ID}-tfstate"; then
  printf "${yellowColor}=> Terraform State Bucket exists...${reset}\n"
else

  fresh_instance=true

  printf "${yellowColor}=> Detected fresh AWS account instance.  Setting up backend S3...${reset}\n"
  # create S3 bucket for Terraform state files
  aws s3api create-bucket \
    --bucket forms-${AWS_ACCOUNT_ID}-tfstate \
    --region ca-central-1 \
    --create-bucket-configuration LocationConstraint=ca-central-1 \
    >/dev/null
  # encrypt the bucket
  aws s3api put-bucket-encryption \
    --bucket forms-${AWS_ACCOUNT_ID}-tfstate \
    --server-side-encryption-configuration "{\"Rules\": [{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\": \"AES256\"}}]}" \
    >/dev/null
fi

if aws dynamodb list-tables | grep -q "tfstate-lock"; then
  printf "${yellowColor}=> Terraform Lock DynamoDB table exists...${reset}\n"
else
  printf "${yellowColor}=> Detected fresh AWS account instance.  Setting up Terraform Lock table...${reset}\n"

  fresh_instance=true

  # create DynamoDB table for Terraform state locking
  aws dynamodb create-table \
    --table-name tfstate-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    >/dev/null
fi

# Build VPN lambda dependencies
printf "${greenColor}=> Building VPN Lambda dependencies${reset}\n"
cd $basedir/aws/vpn/lambda/code
yarn install && yarn build && yarn postbuild

if [ "$fresh_instance" = true ]; then
  printf "${yellowColor}=> Detected fresh AWS account instance.  Clearing local files...${reset}\n"
  for dir in $basedir/env/cloud/*/; do
    rm -rf "${dir}.terragrunt-cache"
    rm -f "${dir}.terraform.lock.hcl"
  done
fi

if [ -z "$MODULE_NAME" ]; then
  printf "${greenColor}=> Building All Terragrunt Modules${reset}\n"
  terragrunt run-all apply \
    --non-interactive --log-level info -auto-approve --queue-strict-include \
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
    --queue-include-dir $basedir/env/cloud/glue
else
  printf "${greenColor}=> Only building ${MODULE_NAME} Terragrunt Module${reset}\n"
  cd $basedir/env/cloud/$MODULE_NAME
  terragrunt apply --non-interactive --log-level info -auto-approve
  exit 0
fi

# Print out the time it took to initialize the infrastructure

t=$SECONDS
printf "${greenColor}All infratructure initialized in %d minutes\nReady for requests${reset}\n" "$((t / 60 - 1440 * (t / 86400)))"

DB_SECRET_ARN=$(aws secretsmanager list-secrets --filter Key="name",Values="server-database-url" --query "SecretList[0].ARN" --output text)
DATABASE_URL=$(aws secretsmanager get-secret-value --secret-id $DB_SECRET_ARN --query "SecretString" --output text)
REDIS_URL=$(aws elasticache describe-cache-clusters --show-cache-node-info --query "CacheClusters[0].CacheNodes[0].Endpoint.Address" --output text)
RELIABILITY_FILE_STORAGE="forms-${AWS_ACCOUNT_ID}-reliability-file-storage"
printf "${greenColor}=> Please copy the following to your app .env file:${reset}\nAWS_PROFILE=${AWS_PROFILE}\nDATABASE_URL=${DATABASE_URL}?connect_timeout=30&pool_timeout=30\nREDIS_URL=${REDIS_URL}:6379\nRELIABILITY_FILE_STORAGE=${RELIABILITY_FILE_STORAGE}\n"
