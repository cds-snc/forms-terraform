#
# Create and Manage PR review environment resources
#
resource "aws_iam_policy" "platform_forms_client_pr_review_env" {
  count  = var.env == "staging" ? 1 : 0
  name   = local.platform_forms_client_pr_review_env
  path   = "/"
  policy = data.aws_iam_policy_document.platform_forms_client_pr_review_env[0].json
}

data "aws_iam_policy_document" "platform_forms_client_pr_review_env" {
  count = var.env == "staging" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "lambda:AddPermission",
      "lambda:CreateFunction",
      "lambda:CreateFunctionUrlConfig",
      "lambda:DeleteFunction",
      "lambda:DeleteFunctionUrlConfig",
      "lambda:DeleteFunctionConcurrency",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetFunctionUrlConfig",
      "lambda:ListFunctionUrlConfigs",
      "lambda:PutFunctionConcurrency",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateFunctionUrlConfig"
    ]
    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:forms-client-pr-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${var.account_id}:role/forms-lambda-client"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream",
      "logs:DeleteRetentionPolicy",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/forms-client-pr-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:SetRepositoryPolicy",
      "ecr:UploadLayerPart"
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${var.account_id}:repository/pr_review"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }
}

#
# Push and manage ECR images
#
resource "aws_iam_policy" "forms_api_release" {
  count  = var.env == "production" ? 1 : 0
  name   = local.forms_api_release
  path   = "/"
  policy = data.aws_iam_policy_document.ecr_push_image[0].json
}

resource "aws_iam_policy" "platform_forms_client_release" {
  count  = var.env == "production" ? 1 : 0
  name   = local.platform_forms_client_release
  path   = "/"
  policy = data.aws_iam_policy_document.ecr_push_image[0].json
}

data "aws_iam_policy_document" "ecr_push_image" {
  count = var.env == "production" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:SetRepositoryPolicy",
      "ecr:UploadLayerPart"
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${var.account_id}:repository/form_viewer_production",
      "arn:aws:ecr:${var.region}:${var.account_id}:repository/forms/api"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}


#
# Upload to S3 and invoke Lambda
#

resource "aws_iam_policy" "forms_db_migration" {
  name   = local.platform_forms_client_db_migration
  path   = "/"
  policy = data.aws_iam_policy_document.forms_db_migration.json
}

data "aws_iam_policy_document" "forms_db_migration" {
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
      "arn:aws:s3:::forms-${var.env}-prisma-migration-storage",
      "arn:aws:s3:::forms-${var.env}-prisma-migration-storage/*"
    ]
  }

  statement {

    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunction"
    ]
    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:prisma-migration",
    ]
  }
}