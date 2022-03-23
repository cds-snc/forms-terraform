output "sqs_reliability_queue_id" {
  description = "SQS reliability queue ID"
  value       = aws_sqs_queue.reliability_queue.id
}

output "sqs_reliability_queue_arn" {
  description = "SQS reliability queue ARN"
  value       = aws_sqs_queue.reliability_queue.arn
}

output "sqs_reprocess_submission_queue_arn" {
  description = "SQS reprocess submission queue ARN"
  value       = aws_sqs_queue.reprocess_submission_queue.arn
}

output "sqs_deadletter_queue_arn" {
  description = "Reliability queue's dead-letter queue ARN"
  value       = aws_sqs_queue.deadletter_queue.name
}
