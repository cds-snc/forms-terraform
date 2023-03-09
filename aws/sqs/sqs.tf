# 
# SQS
# Reliability and dead letter queues
#
resource "aws_sqs_queue" "reliability_queue" {
  name                        = "submission_processing.fifo"
  delay_seconds               = 5
  max_message_size            = 2048
  message_retention_seconds   = 345600
  fifo_queue                  = true
  content_based_deduplication = true
  receive_wait_time_seconds   = 0
  visibility_timeout_seconds  = 1800
  # https://aws.amazon.com/premiumsupport/knowledge-center/lambda-function-process-sqs-messages/
  # The SQS visibility timeout must be at least six times the total of the function timeout and the batch window timeout.
  # Lambda function timeout is 300.

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
    maxReceiveCount     = 5
  })

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sqs_queue" "deadletter_queue" {
  name                        = "deadletter_queue.fifo"
  delay_seconds               = 60
  max_message_size            = 262144
  message_retention_seconds   = 1209600
  fifo_queue                  = true
  content_based_deduplication = true
  receive_wait_time_seconds   = 20

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sqs_queue" "reprocess_submission_queue" {
  name                        = "reprocess_submission_queue.fifo"
  delay_seconds               = 900 // 15 minutes
  max_message_size            = 2048
  message_retention_seconds   = 172800 // 2 days
  fifo_queue                  = true
  content_based_deduplication = true
  receive_wait_time_seconds   = 0
  visibility_timeout_seconds  = 1800
  # https://aws.amazon.com/premiumsupport/knowledge-center/lambda-function-process-sqs-messages/
  # The SQS visibility timeout must be at least six times the total of the function timeout and the batch window timeout.
  # Lambda function timeout is 300.

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
    maxReceiveCount     = 5
  })

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

# Audit Log Queue

resource "aws_sqs_queue" "audit_log_queue" {
  name                       = "audit_log_queue"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 172800 // 2 days
  visibility_timeout_seconds = 1960
  # https://aws.amazon.com/premiumsupport/knowledge-center/lambda-function-process-sqs-messages/
  # The SQS visibility timeout must be at least six times the total of the function timeout and the batch window timeout.
  # Lambda function timeout is 300.

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.audit_log_deadletter_queue.arn
    maxReceiveCount     = 5
  })

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sqs_queue" "audit_log_deadletter_queue" {
  name                      = "audit_log_deadletter_queue"
  delay_seconds             = 60
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 5

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}