output "lambda_audit_logs_log_group_name" {
  description = "Audit logs Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.audit_logs.name
}

output "lambda_audit_logs_archiver_log_group_name" {
  description = "Audit logs archiver Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.audit_logs_archiver.name
}

output "lambda_form_archiver_function_name" {
  description = "Form Archiver Lambda function name"
  value       = aws_lambda_function.form_archiver.function_name
}

output "lambda_form_archiver_log_group_name" {
  description = "Form archiver Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.archive_form_templates.name
}

output "lambda_nagware_function_name" {
  description = "Nagware Lambda function name"
  value       = aws_lambda_function.nagware.function_name
}

output "lambda_nagware_log_group_name" {
  description = "Nagware Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.nagware.name
}

output "lambda_reliability_log_group_name" {
  description = "Reliability Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.reliability.name
}

output "lambda_reliability_dlq_consumer_log_group_name" {
  description = "Reliability DQL consumer Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.dead_letter_queue_consumer.name
}

output "lambda_response_archiver_function_name" {
  description = "Response Archiver Lambda function name"
  value       = aws_lambda_function.response_archiver.function_name
}

output "lambda_response_archiver_log_group_name" {
  description = "Response archiver Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.response_archiver.name
}

output "lambda_submission_log_group_name" {
  description = "Submission Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.submission.name
}

output "lambda_submission_function_name" {
  description = "Submission Lambda function name"
  value       = aws_lambda_function.submission.function_name
}

output "lambda_vault_integrity_log_group_name" {
  description = "Vault integrity Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.vault_integrity.name
}

output "lambda_vault_integrity_function_name" {
  description = "Vault integrity Lambda function name"
  value       = aws_lambda_function.vault_integrity.function_name
}

output "lambda_api_end_to_end_test_log_group_name" {
  description = "API end to end test Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.api_end_to_end_test.name
}

output "lambda_file_upload_processor_log_group_name" {
  description = "File upload processor Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.file_upload.name
}

output "lambda_file_upload_cleanup_log_group_name" {
  description = "File upload cleanup Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.file_upload_cleanup.name
}

output "forms_lambda_client_iam_role_name" {
  description = "IAM role name for forms client Lambda"
  value       = try(aws_iam_role.forms_lambda_client[0].name, null)
}

output "lambda_notification_log_group_name" {
  description = "Notification Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.notification.name
}

output "lambda_notification_function_name" {
  description = "Notification Lambda function name"
  value       = aws_lambda_function.notification.function_name
}
