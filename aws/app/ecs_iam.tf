#
# IAM - Forms ECS task role
#
resource "aws_iam_role" "forms" {
  name               = var.ecs_form_viewer_name
  assume_role_policy = data.aws_iam_policy_document.forms.json
}

data "aws_iam_policy_document" "forms" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "forms_secrets_manager" {
  name   = "formsSecretsManagerKeyRetrieval"
  path   = "/"
  policy = data.aws_iam_policy_document.forms_secrets_manager.json
}

data "aws_iam_policy_document" "forms_secrets_manager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      var.database_url_secret_arn,
      var.recaptcha_secret_arn,
      var.notify_api_key_secret_arn,
      var.token_secret_arn,
      var.notify_callback_bearer_token_secret_arn,
      var.freshdesk_api_key_secret_arn,
      var.zitadel_administration_key_secret_arn,
      var.sentry_api_key_secret_arn
    ]
  }
}

resource "aws_iam_policy" "forms_s3" {
  name   = "formsS3Access"
  path   = "/"
  policy = data.aws_iam_policy_document.forms_s3.json
}

data "aws_iam_policy_document" "forms_s3" {
  statement {
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      var.reliability_file_storage_arn,
      "${var.reliability_file_storage_arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      var.vault_file_storage_arn,
      "${var.vault_file_storage_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_manager_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_secrets_manager.arn
}

resource "aws_iam_role_policy_attachment" "kms_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_kms.arn
}

resource "aws_iam_role_policy_attachment" "s3_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_s3.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "sqs_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_sqs.arn
}

resource "aws_iam_role_policy_attachment" "cognito_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.cognito.arn
}

#
# IAM - SQS
#

resource "aws_iam_policy" "forms_sqs" {
  name        = "forms_sqs"
  path        = "/"
  description = "IAM policy to allow access to SQS for Forms ECS task"
  policy      = data.aws_iam_policy_document.forms_sqs.json
}

data "aws_iam_policy_document" "forms_sqs" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    resources = [
      var.sqs_reprocess_submission_queue_arn,
      var.sqs_app_audit_log_queue_arn
    ]
  }
}

#
# IAM - KMS (for encryption key access - needed for Dynamob DB)
#

resource "aws_iam_policy" "forms_kms" {
  name        = "ecs_kms"
  path        = "/"
  description = "IAM policy for storing encrypting and decrypting data"
  policy      = data.aws_iam_policy_document.forms_kms.json
}

data "aws_iam_policy_document" "forms_kms" {
  statement {
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt"
    ]

    resources = [
      var.kms_key_dynamodb_arn
    ]
  }
}


#
# IAM - Dynamo DB
#
resource "aws_iam_policy" "forms_dynamodb" {
  name        = "forms_dynamodb"
  path        = "/"
  description = "IAM policy for allowing access for Forms ECS task to read and write to the vault"
  policy      = data.aws_iam_policy_document.forms_dynamodb.json
}

data "aws_iam_policy_document" "forms_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
    ]

    resources = [
      var.dynamodb_relability_queue_arn,
      var.dynamodb_vault_arn,
      "${var.dynamodb_vault_arn}/index/*"
    ]
  }
}

#
# IAM - Codedeploy
#
resource "aws_iam_role" "codedeploy" {
  name               = "codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_codedeploy.json
  path               = "/"
}

data "aws_iam_policy_document" "assume_role_policy_codedeploy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

#
# IAM cognito
#

resource "aws_iam_policy" "cognito" {
  name        = "cognito"
  path        = "/"
  description = "IAM policy for allowing ECS access to cognito"


  policy = data.aws_iam_policy_document.assume_role_policy_cognito.json
}

data "aws_iam_policy_document" "assume_role_policy_cognito" {
  statement {
    effect = "Allow"

    actions = [
      "cognito-idp:GetUser",
      "cognito-idp:SignUp",
      "cognito-idp:ConfirmSignUp",
      "cognito-idp:ResendConfirmationCode",
      "cognito-idp:AdminInitiateAuth",
      "cognito-idp:AddCustomAttributes",
      "cognito-idp:AdminUpdateUserAttributes"
    ]

    resources = [
      var.cognito_user_pool_arn
    ]
  }
}