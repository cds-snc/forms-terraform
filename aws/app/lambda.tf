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

  source_code_hash = data.archive_file.reliability_main.output_base64sha256

  runtime = "nodejs14.x"
  layers = [
    aws_lambda_layer_version.reliability_lib.arn,
    aws_lambda_layer_version.reliability_nodejs.arn
  ]

  environment {
    variables = {
      ENVIRONMENT    = var.env
      REGION         = var.region
      NOTIFY_API_KEY = aws_secretsmanager_secret_version.notify_api_key.secret_string
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
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

resource "aws_lambda_layer_version" "reliability_nodejs" {
  filename            = "/tmp/reliability_nodejs.zip"
  layer_name          = "reliability_node_packages"
  source_code_hash    = data.archive_file.reliability_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

resource "aws_lambda_event_source_mapping" "reliability" {
  event_source_arn = var.sqs_reliability_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
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

  source_code_hash = data.archive_file.submission_main.output_base64sha256

  runtime = "nodejs14.x"
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
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

#
# Template Storage processing
#
data "archive_file" "templates_main" {
  type        = "zip"
  source_file = "lambda/templates/templates.js"
  output_path = "/tmp/templates_main.zip"
}

data "archive_file" "templates_lib" {
  type        = "zip"
  source_dir  = "lambda/templates/"
  excludes    = ["templates.js"]
  output_path = "/tmp/templates_lib.zip"
}

resource "aws_lambda_function" "templates" {
  filename      = "/tmp/templates_main.zip"
  function_name = "Templates"
  role          = aws_iam_role.lambda.arn
  handler       = "templates.handler"

  source_code_hash = data.archive_file.templates_main.output_base64sha256
  runtime          = "nodejs14.x"
  layers           = [aws_lambda_layer_version.templates_lib.arn]
  timeout          = "10"

  environment {
    variables = {
      REGION       = var.region
      DB_ARN       = var.rds_cluster_arn
      DB_SECRET    = var.database_secret_arn
      DB_NAME      = var.rds_db_name
      TOKEN_SECRET = aws_secretsmanager_secret_version.token_secret.arn
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

resource "aws_lambda_layer_version" "templates_lib" {
  filename            = "/tmp/templates_lib.zip"
  layer_name          = "templates_node_packages"
  source_code_hash    = data.archive_file.templates_lib.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

#
# User and Organization management
#
data "archive_file" "organizations_main" {
  type        = "zip"
  source_file = "lambda/organizations/organizations.js"
  output_path = "/tmp/organizations_main.zip"
}

data "archive_file" "organizations_lib" {
  type        = "zip"
  source_dir  = "lambda/organizations/"
  excludes    = ["organizations.js"]
  output_path = "/tmp/organizations_lib.zip"
}

resource "aws_lambda_function" "organizations" {
  filename      = "/tmp/organizations_main.zip"
  function_name = "Organizations"
  role          = aws_iam_role.lambda.arn
  handler       = "organizations.handler"

  source_code_hash = data.archive_file.organizations_main.output_base64sha256
  runtime          = "nodejs14.x"
  layers           = [aws_lambda_layer_version.organizations_lib.arn]
  timeout          = "10"

  environment {
    variables = {
      REGION    = var.region
      DB_ARN    = var.rds_cluster_arn
      DB_SECRET = var.database_secret_arn
      DB_NAME   = var.rds_db_name
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

resource "aws_lambda_layer_version" "organizations_lib" {
  filename            = "/tmp/organizations_lib.zip"
  layer_name          = "organizations_node_packages"
  source_code_hash    = data.archive_file.organizations_lib.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

#
# Form responses archiver
#
data "archive_file" "archiver_main" {
  type        = "zip"
  source_file = "lambda/archive_form_responses/archiver.js"
  output_path = "/tmp/archiver_main.zip"
}

data "archive_file" "archiver_lib" {
  type        = "zip"
  source_dir  = "lambda/archive_form_responses/"
  excludes    = ["archiver.js"]
  output_path = "/tmp/archiver_lib.zip"
}

resource "aws_lambda_function" "archiver" {
  filename      = "/tmp/archiver_main.zip"
  function_name = "Archiver"
  role          = aws_iam_role.lambda.arn
  handler       = "archiver.handler"

  source_code_hash = data.archive_file.archiver_main.output_base64sha256
  runtime          = "nodejs14.x"
  layers           = [aws_lambda_layer_version.archiver_lib.arn]
  timeout          = "10"

  environment {
    variables = {
      REGION                    = var.region
      SNS_ERROR_TOPIC_ARN       = var.sns_topic_alert_critical_arn
      DYNAMODB_VAULT_TABLE_NAME = var.dynamodb_vault_table_name
      DYNAMODB_VAULT_INDEX_NAME = var.dynamodb_vault_retrieved_index_name
      ARCHIVING_S3_BUCKET       = aws_s3_bucket.archive_storage.bucket
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
  layer_name          = "archiver_node_packages"
  source_code_hash    = data.archive_file.archiver_lib.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

#
# Lambda permissions
#
resource "aws_lambda_permission" "submission" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submission.function_name
  principal     = aws_iam_role.forms.arn
}

resource "aws_lambda_permission" "templates" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.templates.function_name
  principal     = aws_iam_role.forms.arn
}

resource "aws_lambda_permission" "organizations" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.organizations.function_name
  principal     = aws_iam_role.forms.arn
}

resource "aws_lambda_permission" "internal_templates" {
  statement_id  = "AllowInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.templates.function_name
  principal     = aws_iam_role.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_archiver_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_4am_every_day.arn
}