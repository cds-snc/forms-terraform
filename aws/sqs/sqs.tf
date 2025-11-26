# 
# SQS
# New Standard Reliability and dead letter queues
#
resource "aws_sqs_queue" "reliability_queue" {
  name                       = "reliability_queue"
  delay_seconds              = 5
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 1830
  # https://aws.amazon.com/premiumsupport/knowledge-center/lambda-function-process-sqs-messages/
  # The SQS visibility timeout must be at least six times the total of the function timeout and the batch window timeout.
  # Lambda function timeout is 300.

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.reliability_deadletter_queue.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "reliability_deadletter_queue" {
  name                              = "reliability_deadletter_queue"
  delay_seconds                     = 60
  max_message_size                  = 262144
  message_retention_seconds         = 1209600
  receive_wait_time_seconds         = 20
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_sqs_queue" "reliability_reprocessing_queue" {
  name                       = "reliability_reprocessing_queue"
  delay_seconds              = 900 // 15 minutes
  max_message_size           = 262144
  message_retention_seconds  = 172800 // 2 days
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 1830
  # https://aws.amazon.com/premiumsupport/knowledge-center/lambda-function-process-sqs-messages/
  # The SQS visibility timeout must be at least six times the total of the function timeout and the batch window timeout.
  # Lambda function timeout is 300.

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.reliability_deadletter_queue.arn
    maxReceiveCount     = 5
  })
}


# App Audit Log Queue

resource "aws_sqs_queue" "audit_log_queue" {
  name                       = "audit_log_queue"
  delay_seconds              = 0
  max_message_size           = 262144
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

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.audit_log_deadletter_queue.arn]
  })
}

resource "aws_sqs_queue" "audit_log_deadletter_queue" {
  name                      = "audit_log_deadletter_queue"
  delay_seconds             = 60
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 5

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}

# API Audit Log Queue

resource "aws_sqs_queue" "api_audit_log_queue" {
  name                       = "api_audit_log_queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 172800 // 2 days
  visibility_timeout_seconds = 1960
  # https://aws.amazon.com/premiumsupport/knowledge-center/lambda-function-process-sqs-messages/
  # The SQS visibility timeout must be at least six times the total of the function timeout and the batch window timeout.
  # Lambda function timeout is 300.

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.api_audit_log_deadletter_queue.arn
    maxReceiveCount     = 5
  })

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.api_audit_log_deadletter_queue.arn]
  })
}

resource "aws_sqs_queue" "api_audit_log_deadletter_queue" {
  name                      = "api_audit_log_deadletter_queue"
  delay_seconds             = 60
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 5

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}

# File Upload Verification Queue
resource "aws_sqs_queue" "file_upload_queue" {
  # checkov:skip=CKV_AWS_27: Encrytion not Required and difficult to support with S3 notification source
  name                       = "file_upload_queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 172800 // 2 days
  visibility_timeout_seconds = 1960
  # https://aws.amazon.com/premiumsupport/knowledge-center/lambda-function-process-sqs-messages/
  # The SQS visibility timeout must be at least six times the total of the function timeout and the batch window timeout.
  # Lambda function timeout is 300.

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.file_upload_deadletter_queue.arn
    maxReceiveCount     = 5
  })

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.file_upload_deadletter_queue.arn]
  })
}

resource "aws_sqs_queue" "file_upload_deadletter_queue" {
  # checkov:skip=CKV_AWS_27: Encrytion not Required and difficult to support with S3 notification source
  name                      = "file_upload_deadletter_queue"
  delay_seconds             = 60
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 5
}

# Notification queue (no DLQ requirement)
resource "aws_sqs_queue" "notification_queue" {
  # checkov:skip=CKV_AWS_27: Encrytion not Required and difficult to support with S3 notification source
  name                              = "notification_queue"
  delay_seconds                     = 0
  max_message_size                  = 262144
  message_retention_seconds         = 172800 // 2 days
  visibility_timeout_seconds        = 1800 
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}
