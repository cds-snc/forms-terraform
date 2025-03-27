#!/bin/bash
SECONDS=0
# Exit on any error
set -e

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color

export TG_PROVIDER_CACHE=1

# Set proper terraform and terragrunt versions

tgswitch 0.75.10
tfswitch 1.11.2

basedir=$(pwd)

printf "${greenColor}=> Destroying AWS services${reset}\n"

terragrunt run-all destroy \
    --non-interactive --log-level warn \
    --queue-strict-include \
    -auto-approve \
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

# Remove all the terraform state and lock components
printf "${greenColor}=> Destroying DynamoDB terraform lock table${reset}\n"
dynamodb_tables=$(aws dynamodb list-tables --query "TableNames[?contains(@,'tfstate')]" --output json | jq -r '.[] | @sh' | tr -d \'\")
for table in $dynamodb_tables; do
    printf "${greenColor}=> Destroying DynamoDB table: $table${reset}\n"
    aws dynamodb delete-table --table-name $table >/dev/null
done

printf "${greenColor}=> Destroying S3 terraform state${reset}\n"
s3_buckets=$(aws s3api list-buckets --query "Buckets[?contains(@.Name,'tfstate')].Name" --output json | jq -r '.[] | @sh' | tr -d \'\")
for bucket in $s3_buckets; do
    printf "${greenColor}=> Destroying S3 bucket: $bucket${reset}\n"
    # remove all objects from the bucket
    aws s3 rm s3://$bucket --recursive >/dev/null
    # delete the bucket
    aws s3api delete-bucket --bucket $bucket --region ca-central-1 >/dev/null
done

t=$SECONDS

printf "${greenColor}All infratructure destroyed in %d minutes${reset}\n" "$((t / 60 - 1440 * (t / 86400)))"
