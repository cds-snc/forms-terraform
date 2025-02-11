#
# Holds the Forms app images used by the Elastic Container Service
#
resource "aws_ecr_repository" "viewer_repository" {
  name                 = "form_viewer_${var.env}"
  image_tag_mutability = "MUTABLE"

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
  ecr_names = toset([
    "audit-logs-lambda",
    "audit-logs-archiver-lambda",
    "cognito-email-sender-lambda",
    "cognito-pre-sign-up-lambda",
    "form-archiver-lambda",
    "load-testing-lambda",
    "nagware-lambda",
    "notify-slack-lambda",
    "reliability-lambda",
    "reliability-dlq-consumer-lambda",
    "response-archiver-lambda",
    "submission-lambda",
    "vault-integrity-lambda"
  ])
}

resource "aws_ecr_repository" "lambda" {
  for_each = local.ecr_names

  name                 = each.key
  image_tag_mutability = "MUTABLE"

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

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy     = file("${path.module}/policy/lifecycle.json")
}

resource "aws_ecr_registry_policy" "cross_account_read" {
  count = var.env == "staging" ? 1 : 0
  policy = jsonencode({
    policyText = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          "Sid"       = "AllowCrossAccountPull",
          "Effect"    = "Allow",
          "Principal" = "*",
          "Action" = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:DescribeImages",
            "ecr:DescribeRepositories",
            "ecr:GetDownloadUrlForLayer"
          ],
          "Resource" = "arn:aws:ecr:${var.region}:${var.account_id}:repository/*"
          "Condition" : {
            "StringEquals" : { "aws:PrincipalOrgID" : ["${var.cds_org_id}"] }
          }
        }
      ]
    })
  })
}