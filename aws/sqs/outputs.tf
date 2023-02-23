output "sqs_reliability_queue_id" {
  description = "SQS reliability queue ID"
  value       = aws_sqs_queue.reliability_queue.id
}

output "sqs_dead_letter_queue_id" {
  description = "SQS dead letter queue URL"
  value       = aws_sqs_queue.deadletter_queue.id
}

output "sqs_reliability_queue_arn" {
  description = "SQS reliability queue ARN"
  value       = aws_sqs_queue.reliability_queue.arn
}

output "sqs_reprocess_submission_queue_arn" {
  description = "SQS reprocess submission queue ARN"
  value       = aws_sqs_queue.reprocess_submission_queue.arn
}

output "sqs_reprocess_submission_queue_id" {
  description = "SQS reprocess submission queue URL"
  value       = aws_sqs_queue.reprocess_submission_queue.id
}

output "sqs_deadletter_queue_arn" {
  description = "Reliability queue's dead-letter queue ARN"
  value       = aws_sqs_queue.deadletter_queue.name
}

output "sqs_audit_log_queue_arn" {
  description = "SQS audit log queue ARN"
  value = aws_sqs_queue.audit_log_queue.arn
}

output "sqs_audit_log_queue_id" {
  description = "SQS audit log queue URL"
  value       = aws_sqs_queue.audit_log_queue.id
}

output "sqs_audit_log_deadletter_queue_arn" {
  description = "Audit Log queues dead-letter queue ARN"
  value       = aws_sqs_queue.audit_log_deadletter_queue.arn
}

