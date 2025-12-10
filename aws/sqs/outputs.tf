output "sqs_reliability_queue_id" {
  description = "SQS reliability queue ID"
  value       = aws_sqs_queue.reliability_queue.id
}

output "sqs_reliability_dead_letter_queue_id" {
  description = "SQS Reliability dead letter queue URL"
  value       = aws_sqs_queue.reliability_deadletter_queue.id
}

output "sqs_reliability_queue_arn" {
  description = "SQS reliability queue ARN"
  value       = aws_sqs_queue.reliability_queue.arn
}

output "sqs_reliability_reprocessing_queue_arn" {
  description = "SQS reprocess submission queue ARN"
  value       = aws_sqs_queue.reliability_reprocessing_queue.arn
}

output "sqs_reliability_reprocessing_queue_id" {
  description = "SQS reprocess submission queue URL"
  value       = aws_sqs_queue.reliability_reprocessing_queue.id
}

output "sqs_reliability_deadletter_queue_name" {
  description = "Reliability queue's dead-letter queue name"
  value       = aws_sqs_queue.reliability_deadletter_queue.name
}

output "sqs_app_audit_log_queue_arn" {
  description = "SQS audit log queue ARN"
  value       = aws_sqs_queue.audit_log_queue.arn
}

output "sqs_app_audit_log_queue_id" {
  description = "SQS audit log queue URL"
  value       = aws_sqs_queue.audit_log_queue.id
}

output "sqs_api_audit_log_queue_arn" {
  description = "SQS API audit log queue ARN"
  value       = aws_sqs_queue.api_audit_log_queue.arn
}

output "sqs_api_audit_log_queue_id" {
  description = "SQS API audit log queue URL"
  value       = aws_sqs_queue.api_audit_log_queue.id
}

output "sqs_app_audit_log_deadletter_queue_name" {
  description = "Audit Log queues dead-letter queue name"
  value       = aws_sqs_queue.audit_log_deadletter_queue.name
}

output "sqs_api_audit_log_deadletter_queue_name" {
  description = "API Audit Log queues dead-letter queue name"
  value       = aws_sqs_queue.api_audit_log_deadletter_queue.name
}

output "sqs_file_upload_queue_arn" {
  description = "File Upload queue ARN"
  value       = aws_sqs_queue.file_upload_queue.arn
}

output "sqs_file_upload_queue_id" {
  description = "File Upload queue URL"
  value       = aws_sqs_queue.file_upload_queue.id
}

output "sqs_file_upload_deadletter_queue_name" {
  description = "File upload dead-letter queue name"
  value       = aws_sqs_queue.file_upload_deadletter_queue.name
}

output "sqs_notification_queue_arn" {
  description = "Notification queue ARN"
  value       = aws_sqs_queue.notification_queue.arn
}

output "sqs_notification_queue_url" {
  description = "Notification queue URL"
  value       = aws_sqs_queue.notification_queue.url
}
