output "dynamodb_reliability_queue_arn" {
  description = "Reliability queue DynamodDB table ARN"
  value       = aws_dynamodb_table.reliability_queue.arn
}

output "dynamodb_vault_arn" {
  description = "Vault DynamodDB table ARN"
  value       = aws_dynamodb_table.vault.arn
}

output "dynamodb_vault_table_name" {
  description = "Vault DynamodDB table name"
  value       = aws_dynamodb_table.vault.name
}

output "dynamodb_vault_stream_arn" {
  description = "Vault DynamoDB stream ARN"
  value       = aws_dynamodb_table.vault.stream_arn
}

output "dynamodb_app_audit_logs_arn" {
  description = "App Audit Logs table ARN"
  value       = aws_dynamodb_table.audit_logs.arn
}

output "dynamodb_app_audit_logs_table_name" {
  description = "App Audit Logs table name"
  value       = aws_dynamodb_table.audit_logs.name
}

output "dynamodb_api_audit_logs_arn" {
  description = "API Audit Logs table ARN"
  value       = aws_dynamodb_table.api_audit_logs.arn
}

output "dynamodb_api_audit_logs_table_name" {
  description = "API Audit Logs table name"
  value       = aws_dynamodb_table.api_audit_logs.name
}

output "notification_queue_arn" {
  description = "The ARN of the notification SQS queue"
  value       = aws_sqs_queue.notification_queue.arn
}

output "notification_queue_url" {
  description = "The URL of the notification SQS queue"
  value       = aws_sqs_queue.notification_queue.url
}
