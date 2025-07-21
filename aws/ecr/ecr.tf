#
# Holds the Forms app images used by the Elastic Container Service
#
resource "aws_ecr_repository" "viewer_repository" {
  name                 = "form_viewer_${var.env}"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.env == "development"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "form_viewer_policy" {
  repository = aws_ecr_repository.viewer_repository.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"

      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }

      action = {
        type = "expire"
      }
    }]
  })
}

#
# Holds the containerized Lambda functions
#

locals {
  ecr_names = toset(compact([
    "audit-logs-lambda",
    "audit-logs-archiver-lambda",
    "cognito-email-sender-lambda",
    "cognito-pre-sign-up-lambda",
    "form-archiver-lambda",
    "nagware-lambda",
    "notify-slack-lambda",
    "reliability-lambda",
    "reliability-dlq-consumer-lambda",
    "response-archiver-lambda",
    "submission-lambda",
    "vault-integrity-lambda",
    "prisma-migration-lambda",
    "api-end-to-end-test-lambda",
    "file-upload-processor-lambda",
    "file-upload-cleanup-lambda",
    var.env == "staging" ? "load-testing-lambda" : null
  ]))
}

resource "aws_ecr_repository" "lambda" {
  for_each = local.ecr_names

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = var.env == "development"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "lambda" {
  for_each = local.ecr_names

  repository = aws_ecr_repository.lambda[each.key].name
  policy     = file("${path.module}/policy/lifecycle.json")
}

resource "aws_ecr_repository" "idp" {
  name                 = "idp/zitadel"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.env == "development"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "idp" {
  repository = aws_ecr_repository.idp.name
  policy     = file("${path.module}/policy/lifecycle.json")
}

resource "aws_ecr_repository" "api" {
  name                 = "forms/api"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.env == "development"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy     = file("${path.module}/policy/lifecycle.json")
}

resource "aws_ecr_registry_policy" "cross_account_read" {
  count  = var.env == "staging" ? 1 : 0
  policy = sensitive(data.aws_iam_policy_document.ecr_cross_account_read.json)
}

data "aws_iam_policy_document" "ecr_cross_account_read" {
  statement {
    sid    = "AllowCrossAccountPullOrg"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"

      values = [
        var.cds_org_id,
      ]
    }

    resources = ["arn:aws:ecr:${var.region}:${var.account_id}:repository/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
  statement {
    sid    = "AllowCrossAccountPullLambda"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:sourceAccount"
      values   = var.aws_development_accounts
    }

    resources = ["arn:aws:ecr:${var.region}:${var.account_id}:repository/*"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#
# Holds the Forms app images used by the Rainbow deployment service
#
resource "aws_ecr_repository" "forms_app_legacy_repository" {
  name                 = "forms_app_legacy"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "forms_app_legacy_policy" {
  repository = aws_ecr_repository.forms_app_legacy_repository.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"

      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = 30
      }

      action = {
        type = "expire"
      }
    }]
  })
}
