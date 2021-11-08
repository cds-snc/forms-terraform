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
      aws_secretsmanager_secret_version.notify_api_key.arn,
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
      aws_s3_bucket.reliability_file_storage.id,
      "${aws_s3_bucket.reliability_file_storage.id}/*"
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

resource "aws_iam_role_policy_attachment" "s3_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_s3.arn
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
