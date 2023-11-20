#!/bin/bash

export TF_VAR_cognito_client_id=""
export TF_VAR_cognito_endpoint_url=""
export TF_VAR_cognito_user_pool_arn=""
export TF_VAR_email_address_contact_us=""
export TF_VAR_email_address_support=""
export APP_ENV="local"


color='\033[1;95m' 
reset='\033[0m' # No Color
# Set proper terraform and terragrunt versions

tgswitch 0.53.2
tfswitch 1.6.4

# Usage:
# Without any args will reuse the existing cached packages saving some tiem and bandwidth
# With the 'clean' argument will remove all cached packages for terraform and node modules for lambdas.

basedir=$(pwd)


printf "${color}=> Listing Existing S3 buckets${reset}\n"
cd $basedir/env/cloud/s3

terragrunt refresh | sed s'|: Refreshing state... \[id=| |' | sed s'|\]$||'

# printf "${color}=> Removing S3 buckets from state${reset}\n"
# s3Buckets=(
# aws_s3_bucket.archive_storage
# aws_s3_bucket.lambda_code
# aws_s3_bucket.reliability_file_storage
# aws_s3_bucket.vault_file_storage
# )

# for i in "${s3Buckets[@]}"
# do
#     terragrunt state rm $i
# done