output "ecs_cloudwatch_log_group_name" {
  description = "ECS task's CloudWatch log group name"
  value       = aws_cloudwatch_log_group.forms.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.forms.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.form_viewer.name
}

output "ecs_iam_role_arn" {
  description = "ECS task's IAM role ARN"
  value       = aws_iam_role.forms.arn
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

output "ecs_iam_forms_audit_logs_policy_arn" {
  description = "IAM policy for access to DynamoDB for Audit Logs"
  value       = aws_iam_policy.forms_audit_logs.arn
}


output "ecs_iam_forms_sqs_policy_arn" {
  description = "IAM policy for access to SQS"
  value       = aws_iam_policy.forms_sqs.arn
}

output "ecs_iam_forms_cognito_policy_arn" {
  description = "IAM policy for access to Cognito"
  value       = aws_iam_policy.cognito.arn
}
