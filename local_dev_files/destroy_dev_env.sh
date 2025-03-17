#!/bin/bash
SECONDS=0
# Exit on any error
set -e

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color

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
