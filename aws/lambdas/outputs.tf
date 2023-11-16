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

output "lambda_vault_data_integrity_check_function_name" {
  description = "Vault data integrity check lambda function name"
  value       = aws_lambda_function.vault_integrity.function_name
}

output "lambda_vault_data_integrity_check_log_group_name" {
  description = "Vault data integrity check Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.vault_integrity.name
}