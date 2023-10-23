output "ecs_cloudwatch_log_group_name" {
  description = "ECS task's CloudWatch log group name"
  value       = aws_cloudwatch_log_group.forms.name
}

output "lambda_reliability_log_group_name" {
  description = "Reliability Queues CloudWatch log group name"
  value       = aws_cloudwatch_log_group.reliability.name
}

output "lambda_submission_function_name" {
  description = "Submission lambda function name"
  value       = aws_lambda_function.submission.function_name
}

output "lambda_submission_log_group_name" {
  description = "Submission Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.submission.name
}

output "lambda_archiver_log_group_name" {
  description = "Response Archiver Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.archiver.name
}

output "lambda_dlq_consumer_log_group_name" {
  description = "DQL Consumer CloudWatch log group name"
  value       = aws_cloudwatch_log_group.dead_letter_queue_consumer.name
}

output "lambda_template_archiver_log_group_name" {
  description = "Template Archiver Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.archive_form_templates.name
}

output "lambda_audit_log_group_name" {
  description = "Audit Log Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.audit_logs.name
}

output "lambda_nagware_log_group_name" {
  description = "Nagware Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.nagware.name
}

output "lambda_vault_data_integrity_check_log_group_name" {
  description = "Vault data integrity check Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.vault_data_integrity_check.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.forms.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.form_viewer.name
}

output "ecs_iam_forms_secrets_manager_policy_arn" {
  description = "IAM policy for access to Secrets Manager"
  value       = aws_iam_policy.forms_secrets_manager.arn
}

output "ecs_iam_forms_kms_policy_arn" {
  description = "IAM policy for access to KMS"
  value       = aws_iam_policy.forms_kms.arn
}

output "ecs_iam_forms_s3_policy_arn" {
  description = "IAM policy access to S3"
  value       = aws_iam_policy.forms_s3.arn
}

output "ecs_iam_forms_dynamodb_policy_arn" {
  description = "IAM policy for access to DynamoDB"
  value       = aws_iam_policy.forms_dynamodb.arn
}

output "ecs_iam_forms_sqs_policy_arn" {
  description = "IAM policy for access to SQS"
  value       = aws_iam_policy.forms_sqs.arn
}

output "ecs_iam_forms_cognito_policy_arn" {
  description = "IAM policy for access to Cognito"
  value       = aws_iam_policy.cognito.arn
}
