#
# IAM - Forms ECS task role
#
resource "aws_iam_role" "forms" {
  name               = var.ecs_form_viewer_name
  assume_role_policy = data.aws_iam_policy_document.forms.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "forms_secrets_manager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      var.database_url_secret_arn,
      aws_secretsmanager_secret_version.google_client_id.arn,
      aws_secretsmanager_secret_version.google_client_secret.arn,
      aws_secretsmanager_secret_version.recaptcha_secret.arn,
      aws_secretsmanager_secret_version.notify_api_key.arn,
      aws_secretsmanager_secret_version.token_secret.arn,
      aws_secretsmanager_secret_version.gc_notify_callback_bearer_token.arn
    ]
  }
}

resource "aws_iam_policy" "forms_s3" {
  name   = "formsS3Access"
  path   = "/"
  policy = data.aws_iam_policy_document.forms_s3.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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
      aws_s3_bucket.reliability_file_storage.arn,
      "${aws_s3_bucket.reliability_file_storage.arn}/*"
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

#
# IAM - SQS
#

resource "aws_iam_policy" "forms_sqs" {
  name        = "forms_sqs"
  path        = "/"
  description = "IAM policy to allow access to SQS for Forms ECS task"
  policy      = data.aws_iam_policy_document.forms_sqs.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "forms_sqs" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    resources = [
      var.sqs_reprocess_submission_queue_arn
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "forms_dynamodb" {
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
      "dynamodb:PartiQLSelect",
      "dynamodb:PartiQLDelete",
      "dynamodb:PartiQLInsert",
      "dynamodb:PartiQLUpdate"
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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