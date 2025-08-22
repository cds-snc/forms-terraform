resource "aws_iam_role" "lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_rds" {
  name        = "lambda_rds"
  path        = "/"
  description = "IAM policy for allowing acces to DB"
  policy      = data.aws_iam_policy_document.lambda_rds.json
}

data "aws_iam_policy_document" "lambda_rds" {
  # checkov:skip=CKV_AWS_111: Write access without constraints is allowed
  # checkov:skip=CKV_AWS_356: Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
  // TODO: refactor write access (then we can remove checkov:skip=CKV_AWS_111)
  // TODO: refactor to remove `resources = ["*"]` (then we can remove checkov:skip=CKV_AWS_356)

  statement {
    sid    = "RDSDataServiceAccess"
    effect = "Allow"

    actions = [
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
      "tag:GetResources"
    ]

    resources = ["*"]
  }
}

## Allow Lambda to create and retrieve SQS messages
resource "aws_iam_policy" "lambda_sqs" {
  name        = "lambda_sqs"
  path        = "/"
  description = "IAM policy for sending messages through SQS"
  policy      = data.aws_iam_policy_document.lambda_sqs.json
}

data "aws_iam_policy_document" "lambda_sqs" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [
      "arn:aws:sqs:*:*:*"
    ]
  }
}

## Allow Lambda to access Dynamob DB
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "lambda_dynamobdb"
  path        = "/"
  description = "IAM policy for storing Form responses in DynamoDB"
  policy      = data.aws_iam_policy_document.lambda_dynamodb.json
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams"
    ]

    resources = [
      var.dynamodb_reliability_queue_arn,
      "${var.dynamodb_reliability_queue_arn}/index/*",
      var.dynamodb_vault_arn,
      "${var.dynamodb_vault_arn}/index/*",
      var.dynamodb_vault_stream_arn,
      var.dynamodb_app_audit_logs_arn,
      "${var.dynamodb_app_audit_logs_arn}/index/*",
      var.dynamodb_api_audit_logs_arn,
      "${var.dynamodb_api_audit_logs_arn}/index/*"
    ]
  }
}

# Allow access to lambda to encrypt and decrypt data.
resource "aws_iam_policy" "lambda_kms" {
  name        = "lambda_kms"
  path        = "/"
  description = "IAM policy for storing encrypting and decrypting data"
  policy      = data.aws_iam_policy_document.lambda_kms.json
}

data "aws_iam_policy_document" "lambda_kms" {
  statement {
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt"
    ]

    resources = [
      var.kms_key_dynamodb_arn,
      var.kms_key_cloudwatch_arn
    ]
  }
}

# Allow access to lambda to secrets manager.
resource "aws_iam_policy" "lambda_secrets" {
  name        = "lambda_secrets"
  path        = "/"
  description = "IAM policy for accessing secret manager"
  policy      = data.aws_iam_policy_document.lambda_secrets.json
}

data "aws_iam_policy_document" "lambda_secrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.database_secret_arn,
      var.notify_api_key_secret_arn,
      var.database_url_secret_arn,
    ]
  }
}

# Allow lambda to access S3 buckets

resource "aws_iam_policy" "lambda_s3" {
  name        = "lambda_s3"
  path        = "/"
  description = "IAM policy for storing files in S3"
  policy      = data.aws_iam_policy_document.lambda_s3.json
}

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging"
    ]

    resources = [
      var.reliability_file_storage_arn,
      "${var.reliability_file_storage_arn}/*",
      var.vault_file_storage_arn,
      "${var.vault_file_storage_arn}/*",
      var.archive_storage_arn,
      "${var.archive_storage_arn}/*",
      var.audit_logs_archive_storage_arn,
      "${var.audit_logs_archive_storage_arn}/*",
      var.prisma_migration_storage_arn,
      "${var.prisma_migration_storage_arn}/*"
    ]
  }
}

## Allow Lambda to access SNS
resource "aws_iam_policy" "lambda_sns" {
  name        = "lambda_sns"
  path        = "/"
  description = "IAM policy for allowing lambda to publish message in SNS for Slack notification"
  policy      = data.aws_iam_policy_document.lambda_sns.json
}

data "aws_iam_policy_document" "lambda_sns" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      var.sns_topic_alert_critical_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_xray" {
  name        = "lambda_xray"
  path        = "/"
  description = "IAM policy for allowing X-Ray tracing"
  policy      = data.aws_iam_policy_document.lambda_xray.json
}

data "aws_iam_policy_document" "lambda_xray" {
  statement {
    effect = "Allow"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries",
      "ssm:GetParameters"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_secrets.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_sqs.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "lambda_kms" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_kms.arn
}

resource "aws_iam_role_policy_attachment" "lambda_rds" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_rds.arn
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_s3.arn
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_sns.arn
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_xray.arn
}



// This is required by the API end to end test lambda function

resource "aws_lambda_permission" "allow_submission_lambda_invoke" {
  statement_id  = "AllowSubmissionInvokeFromLambda"
  action        = "lambda:InvokeFunction"
  principal     = aws_iam_role.lambda.arn
  function_name = aws_lambda_function.submission.function_name
}
