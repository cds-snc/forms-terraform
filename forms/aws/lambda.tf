resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

###
# AWS Lambda - Notifiy Slack
###
data "archive_file" "notify_slack" {
  type        = "zip"
  source_file = "lambda/notify_slack/notify_slack.js"
  output_path = "/tmp/notify_slack.zip"
}

resource "aws_lambda_function" "notify_slack_sns" {
  filename      = "/tmp/notify_slack.zip"
  function_name = "NotifySlackSNS"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "notify_slack.handler"

  source_code_hash = data.archive_file.notify_slack.output_base64sha256

  runtime = "nodejs14.x"

  environment {
    variables = {
      SLACK_WEBHOOK = var.slack_webhook
    }
  }

}
###
# AWS Lambda - Reliability Queue Processing
###
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
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "reliability.handler"

  source_code_hash = data.archive_file.reliability_main.output_base64sha256

  runtime = "nodejs14.x"
  layers  = [aws_lambda_layer_version.reliability_lib.arn, aws_lambda_layer_version.reliability_nodejs.arn]

  environment {
    variables = {
      REGION         = var.region
      NOTIFY_API_KEY = aws_secretsmanager_secret_version.notify_api_key.secret_string
    }
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
  event_source_arn = aws_sqs_queue.reliability_queue.arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
}

###
# AWS Lambda - Form Submission API processing
###

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
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "submission.handler"

  source_code_hash = data.archive_file.submission_main.output_base64sha256

  runtime = "nodejs14.x"
  layers  = [aws_lambda_layer_version.submission_lib.arn]

  environment {
    variables = {
      REGION  = var.region,
      SQS_URL = aws_sqs_queue.reliability_queue.id
    }
  }

}

resource "aws_lambda_layer_version" "submission_lib" {
  filename            = "/tmp/submission_lib.zip"
  layer_name          = "submission_node_packages"
  source_code_hash    = data.archive_file.submission_lib.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

###
# AWS Lambda - Template Storage processing
###

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
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "templates.handler"

  source_code_hash = data.archive_file.templates_main.output_base64sha256
  runtime          = "nodejs14.x"
  layers           = [aws_lambda_layer_version.templates_lib.arn]
  timeout          = "10"

  environment {
    variables = {
      REGION    = var.region,
      DB_ARN    = aws_rds_cluster.forms.arn,
      DB_SECRET = aws_secretsmanager_secret_version.database_secret.arn,
      DB_NAME   = var.rds_db_name
    }
  }
}

resource "aws_lambda_layer_version" "templates_lib" {
  filename            = "/tmp/templates_lib.zip"
  layer_name          = "templates_node_packages"
  source_code_hash    = data.archive_file.templates_lib.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

###
# AWS Lambda - User and Organisation management
###
data "archive_file" "organisations_main" {
  type        = "zip"
  source_file = "lambda/organisations/organisations.js"
  output_path = "/tmp/organisations_main.zip"
}

data "archive_file" "organisations_lib" {
  type        = "zip"
  source_dir  = "lambda/organisations/"
  excludes    = ["organisations.js"]
  output_path = "/tmp/organisations_lib.zip"
}

resource "aws_lambda_function" "organisations" {
  filename      = "/tmp/organisations_main.zip"
  function_name = "Organisations"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "organisations.handler"

  source_code_hash = data.archive_file.organisations_main.output_base64sha256
  runtime          = "nodejs14.x"
  layers           = [aws_lambda_layer_version.organisations_lib.arn]
  timeout          = "10"

  environment {
    variables = {
      REGION    = var.region,
      DB_ARN    = aws_rds_cluster.forms.arn,
      DB_SECRET = aws_secretsmanager_secret_version.database_secret.arn,
      DB_NAME   = var.rds_db_name
    }
  }
}

resource "aws_lambda_layer_version" "organisations_lib" {
  filename            = "/tmp/organisations_lib.zip"
  layer_name          = "organisations_node_packages"
  source_code_hash    = data.archive_file.organisations_lib.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}


###
# Vault Retrieval 
###

data "archive_file" "retrieval_main" {
  type        = "zip"
  source_file = "lambda/retrieval/retrieval.js"
  output_path = "/tmp/retrieval_main.zip"
}

data "archive_file" "retrieval_lib" {
  type        = "zip"
  source_dir  = "lambda/retrieval/"
  excludes    = ["retrieval.js"]
  output_path = "/tmp/retrieval_lib.zip"
}

resource "aws_lambda_function" "retrieval" {
  filename      = "/tmp/retrieval_main.zip"
  function_name = "Retrieval"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "retrieval.handler"

  source_code_hash = data.archive_file.retrieval_main.output_base64sha256
  runtime          = "nodejs14.x"
  layers           = [aws_lambda_layer_version.retrieval_lib.arn]

  environment {
    variables = {
      REGION    = var.region,
      DB_ARN    = aws_rds_cluster.forms.arn,
      DB_SECRET = aws_secretsmanager_secret_version.database_secret.arn,
      DB_NAME   = var.rds_db_name
    }
  }
}

resource "aws_lambda_layer_version" "retrieval_lib" {
  filename            = "/tmp/retrieval_lib.zip"
  layer_name          = "retrieval_node_packages"
  source_code_hash    = data.archive_file.retrieval_lib.output_base64sha256
  compatible_runtimes = ["nodejs12.x", "nodejs14.x"]
}

###
# Load Testing
###
data "archive_file" "load_testing" {
  type        = "zip"
  source_dir  = "lambda/load_testing/"
  output_path = "/tmp/load_testing.zip"
}

resource "aws_lambda_function" "load_testing" {
  filename         = "/tmp/load_testing.zip"
  function_name    = "LoadTesting"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_locust.handler"
  timeout          = 300
  memory_size      = 200
  source_code_hash = data.archive_file.load_testing.output_base64sha256

  runtime     = "python3.8"
  description = "A function that runs a locust load test"

  environment {
    variables = {
      LOCUST_RUN_TIME    = "3m"
      LOCUST_LOCUSTFILE  = "locust_test_file.py"
      LOCUST_HOST        = "https://forms-staging.cdssandbox.xyz"
      LOCUST_HATCH_RATE  = "1"
      LOCUST_NUM_CLIENTS = "1"
    }
  }

}



## Allow SNS to call Lambda function

resource "aws_lambda_permission" "notify_slack_warning" {
  statement_id  = "AllowExecutionFromSNSWarningAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_warning.arn
}

resource "aws_lambda_permission" "notify_slack_critical" {
  statement_id  = "AllowExecutionFromSNSCriticalAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_critical.arn
}

resource "aws_lambda_permission" "notify_slack_ok" {
  statement_id  = "AllowExecutionFromSNSOkAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_ok.arn
}

# Allow ECS containers to call Lambdas
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

resource "aws_lambda_permission" "retrieval" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retrieval.function_name
  principal     = aws_iam_role.forms.arn
}


# Allow Lambda to call templates function
resource "aws_lambda_permission" "internal_templates" {
  statement_id  = "AllowInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.templates.function_name
  principal     = aws_iam_role.iam_for_lambda.arn
}

## Allow Lambda to create Logs in Cloudwatch

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_rds" {
  name        = "lambda_rds"
  path        = "/"
  description = "IAM policy for allowing acces to DB"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RDSDataServiceAccess",
      "Effect": "Allow",
      "Action": [
          "dbqms:CreateFavoriteQuery",
          "dbqms:DescribeFavoriteQueries",
          "dbqms:UpdateFavoriteQuery",
          "dbqms:DeleteFavoriteQueries",
          "dbqms:GetQueryString",
          "dbqms:CreateQueryHistory",
          "dbqms:DescribeQueryHistory",
          "dbqms:UpdateQueryHistory",
          "dbqms:DeleteQueryHistory",
          "rds-data:ExecuteSql",
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction",
          "secretsmanager:CreateSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:GetRandomPassword",
          "tag:GetResources"
      ],
      "Resource": "*"
    }
  ]
}
  EOF
}

## Allow Lambda to create and retrieve SQS messages
resource "aws_iam_policy" "lambda_sqs" {
  name        = "lambda_sqs"
  path        = "/"
  description = "IAM policy for sending messages through SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
## Allow Lambda to access Dynamob DB
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "lambda_dynamobdb"
  path        = "/"
  description = "IAM policy for storing Form responses in DynamoDB"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      "Resource": [
        "${aws_dynamodb_table.reliability_queue.arn}",
        "${aws_dynamodb_table.vault.arn}"
        ],
      "Effect": "Allow"
    }
  ]
}
EOF
}
# Allow access to lambda to encrypt and decrypt data.
resource "aws_iam_policy" "lambda_kms" {
  name        = "lambda_kms"
  path        = "/"
  description = "IAM policy for storing encrypting and decrypting data"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:GenerateDataKey",
        "kms:Encrypt",
        "kms:Decrypt"
      ],
      "Resource": ["${aws_kms_key.dynamoDB.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Allow access to lambda to secrets manager.
resource "aws_iam_policy" "lambda_secrets" {
  name        = "lambda_secrets"
  path        = "/"
  description = "IAM policy for accessing secret manager"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${aws_secretsmanager_secret_version.notify_api_key.arn}",
        "${aws_secretsmanager_secret_version.database_secret.arn}"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_secrets.arn

}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_sqs.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "lambda_kms" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_kms.arn
}

resource "aws_iam_role_policy_attachment" "lambda_rds" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_rds.arn
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


## Allow Lambda to create and retrieve SQS messages
resource "aws_iam_policy" "lambda_app_invoke" {
  name        = "lambda_app_invoke"
  path        = "/"
  description = "IAM policy for allowing the Forms app to invoke Lambda functions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "${aws_lambda_function.retrieval.arn}",
        "${aws_lambda_function.templates.arn}",
        "${aws_lambda_function.submission.arn}"      
      ]
    }
  ]
}
EOF
}
