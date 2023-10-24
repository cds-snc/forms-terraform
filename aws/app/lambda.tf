#
# Reliability Queue Processing
#
data "archive_file" "reliability_main" {
  type        = "zip"
  source_file = "lambda/reliability/reliability.js"
  output_path = "/tmp/reliability_main.zip"
}

data "archive_file" "reliability_lib" {
  type        = "zip"
  output_path = "/tmp/reliability_lib.zip"

  source {
    content  = file("./lambda/reliability/lib/markdown.js")
    filename = "nodejs/node_modules/markdown/index.js"
  }

  source {
    content  = file("./lambda/reliability/lib/templates.js")
    filename = "nodejs/node_modules/templates/index.js"
  }

  source {
    content  = file("./lambda/reliability/lib/dataLayer.js")
    filename = "nodejs/node_modules/dataLayer/index.js"
  }

  source {
    content  = file("./lambda/reliability/lib/notifyProcessing.js")
    filename = "nodejs/node_modules/notifyProcessing/index.js"
  }

  source {
    content  = file("./lambda/reliability/lib/vaultProcessing.js")
    filename = "nodejs/node_modules/vaultProcessing/index.js"
  }

  source {
    content  = file("./lambda/reliability/lib/s3FileInput.js")
    filename = "nodejs/node_modules/s3FileInput/index.js"
  }
}

data "archive_file" "reliability_nodejs" {
  type        = "zip"
  source_dir  = "lambda/reliability/"
  excludes    = ["reliability.js", "./lib", ]
  output_path = "/tmp/reliability_nodejs.zip"
}

resource "aws_lambda_function" "reliability" {
  filename      = "/tmp/reliability_main.zip"
  function_name = "Reliability"
  role          = aws_iam_role.lambda.arn
  handler       = "reliability.handler"
  timeout       = 300

  source_code_hash = data.archive_file.reliability_main.output_base64sha256

  runtime = "nodejs18.x"
  layers = [
    aws_lambda_layer_version.reliability_lib.arn,
    aws_lambda_layer_version.reliability_nodejs.arn
  ]

  environment {
    variables = {
      ENVIRONMENT    = var.env
      REGION         = var.region
      NOTIFY_API_KEY = aws_secretsmanager_secret_version.notify_api_key.secret_string
      TEMPLATE_ID    = var.gc_template_id
      DB_ARN         = var.rds_cluster_arn
      DB_SECRET      = var.database_secret_arn
      DB_NAME        = var.rds_db_name

    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_layer_version" "reliability_lib" {
  filename            = "/tmp/reliability_lib.zip"
  layer_name          = "reliability_lib_packages"
  source_code_hash    = data.archive_file.reliability_lib.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_layer_version" "reliability_nodejs" {
  filename            = "/tmp/reliability_nodejs.zip"
  layer_name          = "reliability_node_packages"
  source_code_hash    = data.archive_file.reliability_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_event_source_mapping" "reliability" {
  event_source_arn = var.sqs_reliability_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "reprocess_submission" {
  event_source_arn = var.sqs_reprocess_submission_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_cloudwatch_log_group" "reliability" {
  name              = "/aws/lambda/${aws_lambda_function.reliability.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}

#
# Form Submission API processing
#
data "archive_file" "submission_main" {
  type        = "zip"
  source_file = "lambda/submission/submission.js"
  output_path = "/tmp/submission_main.zip"
}

data "archive_file" "submission_lib" {
  type        = "zip"
  source_dir  = "lambda/submission/"
  excludes    = ["submission.js"]
  output_path = "/tmp/submission_lib.zip"
}

resource "aws_lambda_function" "submission" {
  filename      = "/tmp/submission_main.zip"
  function_name = "Submission"
  role          = aws_iam_role.lambda.arn
  handler       = "submission.handler"
  timeout       = 60


  source_code_hash = data.archive_file.submission_main.output_base64sha256

  runtime = "nodejs18.x"
  layers = [
    aws_lambda_layer_version.submission_lib.arn
  ]

  environment {
    variables = {
      REGION  = var.region
      SQS_URL = var.sqs_reliability_queue_id
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }

}

resource "aws_lambda_layer_version" "submission_lib" {
  filename            = "/tmp/submission_lib.zip"
  layer_name          = "submission_node_packages"
  source_code_hash    = data.archive_file.submission_lib.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_permission" "submission" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submission.function_name
  principal     = aws_iam_role.forms.arn
}

resource "aws_cloudwatch_log_group" "submission" {
  name              = "/aws/lambda/${aws_lambda_function.submission.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}


#
# Archive form responses
#
data "archive_file" "archiver_main" {
  type        = "zip"
  source_file = "lambda/archive_form_responses/archiver.js"
  output_path = "/tmp/archiver_main.zip"
}

data "archive_file" "archiver_lib" {
  type        = "zip"
  output_path = "/tmp/archiver_lib.zip"

  source {
    content  = file("./lambda/archive_form_responses/lib/fileAttachments.js")
    filename = "nodejs/node_modules/fileAttachments/index.js"
  }
}

data "archive_file" "archiver_nodejs" {
  type        = "zip"
  source_dir  = "lambda/archive_form_responses/"
  excludes    = ["archiver.js", "./lib", ]
  output_path = "/tmp/archiver_nodejs.zip"
}

resource "aws_lambda_function" "archiver" {
  filename      = "/tmp/archiver_main.zip"
  function_name = "Archiver"
  role          = aws_iam_role.lambda.arn
  handler       = "archiver.handler"

  source_code_hash = data.archive_file.archiver_main.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 10
  layers = [
    aws_lambda_layer_version.archiver_lib.arn,
    aws_lambda_layer_version.archiver_nodejs.arn
  ]

  environment {
    variables = {
      REGION                       = var.region
      DYNAMODB_VAULT_TABLE_NAME    = var.dynamodb_vault_table_name
      ARCHIVING_S3_BUCKET          = aws_s3_bucket.archive_storage.bucket
      VAULT_FILE_STORAGE_S3_BUCKET = aws_s3_bucket.vault_file_storage.bucket
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_layer_version" "archiver_lib" {
  filename            = "/tmp/archiver_lib.zip"
  layer_name          = "archiver_lib_packages"
  source_code_hash    = data.archive_file.archiver_lib.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_layer_version" "archiver_nodejs" {
  filename            = "/tmp/archiver_nodejs.zip"
  layer_name          = "archiver_node_packages"
  source_code_hash    = data.archive_file.archiver_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_archive_form_responses_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_3am_every_day.arn
}

resource "aws_cloudwatch_log_group" "archiver" {
  name              = "/aws/lambda/${aws_lambda_function.archiver.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}


#
# Dead letter queue consumer
#

data "archive_file" "dead_letter_queue_consumer_main" {
  type        = "zip"
  source_file = "lambda/dead_letter_queue_consumer/dead_letter_queue_consumer.js"
  output_path = "/tmp/dead_letter_queue_consumer_main.zip"
}

data "archive_file" "dead_letter_queue_consumer_lib" {
  type        = "zip"
  source_dir  = "lambda/dead_letter_queue_consumer/"
  excludes    = ["dead_letter_queue_consumer.js"]
  output_path = "/tmp/dead_letter_queue_consumer_lib.zip"
}

resource "aws_lambda_function" "dead_letter_queue_consumer" {
  filename      = "/tmp/dead_letter_queue_consumer_main.zip"
  function_name = "DeadLetterQueueConsumer"
  role          = aws_iam_role.lambda.arn
  handler       = "dead_letter_queue_consumer.handler"

  source_code_hash = data.archive_file.dead_letter_queue_consumer_main.output_base64sha256
  runtime          = "nodejs18.x"
  layers           = [aws_lambda_layer_version.dead_letter_queue_consumer_lib.arn]
  timeout          = 300

  environment {
    variables = {
      REGION                              = var.region
      SQS_DEAD_LETTER_QUEUE_URL           = var.sqs_reliability_dead_letter_queue_id
      SQS_SUBMISSION_PROCESSING_QUEUE_URL = var.sqs_reliability_queue_id
      SNS_ERROR_TOPIC_ARN                 = var.sns_topic_alert_critical_arn
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_layer_version" "dead_letter_queue_consumer_lib" {
  filename            = "/tmp/dead_letter_queue_consumer_lib.zip"
  layer_name          = "dead_letter_queue_consumer_node_packages"
  source_code_hash    = data.archive_file.dead_letter_queue_consumer_lib.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_dead_letter_queue_consumer_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dead_letter_queue_consumer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_2am_every_day.arn
}

resource "aws_cloudwatch_log_group" "dead_letter_queue_consumer" {
  name              = "/aws/lambda/${aws_lambda_function.dead_letter_queue_consumer.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}


#
# Archive form templates
#

data "archive_file" "archive_form_templates_main" {
  type        = "zip"
  source_file = "lambda/archive_form_templates/archiver.js"
  output_path = "/tmp/archive_form_templates_main.zip"
}

data "archive_file" "archive_form_templates_lib" {
  type        = "zip"
  output_path = "/tmp/archive_form_templates_lib.zip"

  source {
    content  = file("./lambda/archive_form_templates/lib/templates.js")
    filename = "nodejs/node_modules/templates/index.js"
  }
}

data "archive_file" "archive_form_templates_nodejs" {
  type        = "zip"
  source_dir  = "lambda/archive_form_templates/"
  excludes    = ["archiver.js", "./lib", ]
  output_path = "/tmp/archive_form_templates_nodejs.zip"
}

resource "aws_lambda_function" "archive_form_templates" {
  filename      = "/tmp/archive_form_templates_main.zip"
  function_name = "ArchiveFormTemplates"
  role          = aws_iam_role.lambda.arn
  handler       = "archiver.handler"
  timeout       = 300

  source_code_hash = data.archive_file.archive_form_templates_main.output_base64sha256

  runtime = "nodejs18.x"
  layers = [
    aws_lambda_layer_version.archive_form_templates_lib.arn,
    aws_lambda_layer_version.archive_form_templates_nodejs.arn
  ]

  environment {
    variables = {
      ENVIRONMENT = var.env
      REGION      = var.region
      DB_ARN      = var.rds_cluster_arn
      DB_SECRET   = var.database_secret_arn
      DB_NAME     = var.rds_db_name
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_layer_version" "archive_form_templates_lib" {
  filename            = "/tmp/archive_form_templates_lib.zip"
  layer_name          = "archive_form_templates_lib_packages"
  source_code_hash    = data.archive_file.archive_form_templates_lib.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_layer_version" "archive_form_templates_nodejs" {
  filename            = "/tmp/archive_form_templates_nodejs.zip"
  layer_name          = "archive_form_templates_node_packages"
  source_code_hash    = data.archive_file.archive_form_templates_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_archive_form_templates_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.archive_form_templates.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_4am_every_day.arn
}

resource "aws_cloudwatch_log_group" "archive_form_templates" {
  name              = "/aws/lambda/${aws_lambda_function.archive_form_templates.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}


#
# Audit Log Processing
#
data "archive_file" "audit_logs_main" {
  type        = "zip"
  source_file = "lambda/audit_logs/audit_logs.js"
  output_path = "/tmp/audit_logs_main.zip"
}

data "archive_file" "audit_logs_lib" {
  type        = "zip"
  source_dir  = "lambda/audit_logs/"
  excludes    = ["audit_logs.js"]
  output_path = "/tmp/audit_logs_lib.zip"
}

resource "aws_lambda_function" "audit_logs" {
  filename      = "/tmp/audit_logs_main.zip"
  function_name = "AuditLogs"
  role          = aws_iam_role.lambda.arn
  handler       = "audit_logs.handler"
  timeout       = 60

  source_code_hash = data.archive_file.audit_logs_main.output_base64sha256

  runtime = "nodejs18.x"
  layers = [
    aws_lambda_layer_version.audit_logs_lib.arn
  ]

  environment {
    variables = {
      REGION = var.region
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }

}

resource "aws_lambda_layer_version" "audit_logs_lib" {
  filename            = "/tmp/audit_logs_lib.zip"
  layer_name          = "audit_logs_node_packages"
  source_code_hash    = data.archive_file.audit_logs_lib.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_event_source_mapping" "audit_logs" {
  event_source_arn                   = var.sqs_audit_log_queue_arn
  function_name                      = aws_lambda_function.audit_logs.arn
  function_response_types            = ["ReportBatchItemFailures"]
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  enabled                            = true
}

resource "aws_cloudwatch_log_group" "audit_logs" {
  name              = "/aws/lambda/${aws_lambda_function.audit_logs.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}


#
# Nagware
#

data "archive_file" "nagware_main" {
  type        = "zip"
  source_file = "lambda/nagware/nagware.js"
  output_path = "/tmp/nagware_main.zip"
}

data "archive_file" "nagware_lib" {
  type        = "zip"
  output_path = "/tmp/nagware_lib.zip"

  source {
    content  = file("./lambda/nagware/lib/dynamodbDataLayer.js")
    filename = "nodejs/node_modules/dynamodbDataLayer/index.js"
  }

  source {
    content  = file("./lambda/nagware/lib/templates.js")
    filename = "nodejs/node_modules/templates/index.js"
  }

  source {
    content  = file("./lambda/nagware/lib/emailNotification.js")
    filename = "nodejs/node_modules/emailNotification/index.js"
  }
}

data "archive_file" "nagware_nodejs" {
  type        = "zip"
  source_dir  = "lambda/nagware/"
  excludes    = ["nagware.js", "./lib", ]
  output_path = "/tmp/nagware_nodejs.zip"
}

resource "aws_lambda_function" "nagware" {
  filename      = "/tmp/nagware_main.zip"
  function_name = "Nagware"
  role          = aws_iam_role.lambda.arn
  handler       = "nagware.handler"
  timeout       = 300

  source_code_hash = data.archive_file.nagware_main.output_base64sha256

  runtime = "nodejs18.x"
  layers = [
    aws_lambda_layer_version.nagware_lib.arn,
    aws_lambda_layer_version.nagware_nodejs.arn
  ]

  environment {
    variables = {
      ENVIRONMENT               = var.env
      REGION                    = var.region
      DOMAIN                    = var.domain
      DYNAMODB_VAULT_TABLE_NAME = var.dynamodb_vault_table_name
      DB_ARN                    = var.rds_cluster_arn
      DB_SECRET                 = var.database_secret_arn
      DB_NAME                   = var.rds_db_name
      NOTIFY_API_KEY            = aws_secretsmanager_secret_version.notify_api_key.secret_string
      TEMPLATE_ID               = var.gc_template_id
      SNS_ERROR_TOPIC_ARN       = var.sns_topic_alert_critical_arn
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_layer_version" "nagware_lib" {
  filename            = "/tmp/nagware_lib.zip"
  layer_name          = "nagware_lib_packages"
  source_code_hash    = data.archive_file.nagware_lib.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_layer_version" "nagware_nodejs" {
  filename            = "/tmp/nagware_nodejs.zip"
  layer_name          = "nagware_node_packages"
  source_code_hash    = data.archive_file.nagware_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_nagware_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nagware.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_5am_every_business_day.arn
}

resource "aws_cloudwatch_log_group" "nagware" {
  name              = "/aws/lambda/${aws_lambda_function.nagware.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}


#
# Archive Audit Logs
#
data "archive_file" "archive_audit_logs_main" {
  type        = "zip"
  source_file = "lambda/archive_audit_logs/archiver.js"
  output_path = "/tmp/archive_audit_logs_main.zip"
}

data "archive_file" "archive_audit_logs_lib" {
  type        = "zip"
  source_dir  = "lambda/archive_audit_logs/"
  excludes    = ["archiver.js"]
  output_path = "/tmp/archive_audit_logs_lib.zip"
}

resource "aws_lambda_function" "archive_audit_logs" {
  filename      = "/tmp/archive_audit_logs_main.zip"
  function_name = "ArchiveAuditLogs"
  role          = aws_iam_role.lambda.arn
  handler       = "archiver.handler"
  timeout       = 120

  source_code_hash = data.archive_file.archive_audit_logs_main.output_base64sha256

  runtime = "nodejs16.x"
  layers = [
    aws_lambda_layer_version.archive_audit_logs_lib.arn
  ]

  environment {
    variables = {
      REGION                      = var.region
      AUDIT_LOG_ARCHIVE_S3_BUCKET = aws_s3_bucket.audit_logs_archive_storage.bucket
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }

}

resource "aws_lambda_layer_version" "archive_audit_logs_lib" {
  filename            = "/tmp/archive_audit_logs_lib.zip"
  layer_name          = "archive_audit_logs_node_packages"
  source_code_hash    = data.archive_file.archive_audit_logs_lib.output_base64sha256
  compatible_runtimes = ["nodejs14.x", "nodejs16.x"]
}

resource "aws_lambda_event_source_mapping" "archive_audit_logs" {
  event_source_arn                   = aws_dynamodb_table.audit_logs.stream_arn
  function_name                      = aws_lambda_function.archive_audit_logs.arn
  starting_position                  = "LATEST"
  batch_size                         = 100
  maximum_batching_window_in_seconds = 15
  enabled                            = true
  MaximumRetryAttempts               = 3
  filter_criteria_json = jsonencode({
    Filters = [
      {
        Pattern = "{\"userIdentity\":{\"type\":[\"Service\"],\"principalId\":[\"dynamodb.amazonaws.com\"]}}"
      }
    ]
  })

}

resource "aws_cloudwatch_log_group" "archive_audit_logs" {
  name              = "/aws/lambda/${aws_lambda_function.archive_audit_logs.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}
