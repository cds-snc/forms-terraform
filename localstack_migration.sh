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

tgswitch 0.53.8
tfswitch 1.6.6

ACTION=$1
DRY_RUN="-dry-run"

if [[ "$ACTION" == "for_real" ]]; then
    DRY_RUN=""
fi

basedir=$(pwd)

cd $basedir/env/cloud/app
printf "${color}=> Removing S3 buckets from state${reset}\n"
s3Buckets=(
    aws_s3_bucket.archive_storage
    aws_s3_bucket.lambda_code
    aws_s3_bucket.reliability_file_storage
    aws_s3_bucket.vault_file_storage
)

for i in "${s3Buckets[@]}"
do
    terragrunt state rm $DRY_RUN $i
done

printf "${color}=> Removing Cloudwatch logs from state${reset}\n"

cloudwatchLogs=(
    aws_cloudwatch_log_group.reliability
    aws_cloudwatch_log_group.submission
    aws_cloudwatch_log_group.archiver
    aws_cloudwatch_log_group.dead_letter_queue_consumer
    aws_cloudwatch_log_group.archive_form_templates
    aws_cloudwatch_log_group.audit_logs
    aws_cloudwatch_log_group.nagware
    aws_cloudwatch_log_group.vault_data_integrity_check
)

for i in "${cloudwatchLogs[@]}"
do
    terragrunt state rm $DRY_RUN $i
done