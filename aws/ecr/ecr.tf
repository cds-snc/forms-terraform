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
    "form-archiver-lambda",
    "nagware-lambda",
    "reliability-lambda",
    "reliability-dlq-consumer-lambda",
    "response-archiver-lambda",
    "submission-lambda",
    "vault-integrity-lambda",
    "notify-slack-lambda",
    "cognito-email-sender-lambda",
    "cognito-pre-sign-up-lambda"
  ])
}

resource "aws_ecr_repository" "lambda" {
  for_each = local.ecr_names

  name                 = each.key
  image_tag_mutability = var.env == "production" ? "IMMUTABLE" : "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "lambda" {
  for_each = local.ecr_names

  repository = aws_ecr_repository.lambda[each.key].name
  policy     = file("${path.module}/policy/lambda_lifecycle.json")
}

#
# Holds the Load Test image used by the Lambda
#
resource "aws_ecr_repository" "load_test_repository" {
  count                = var.env == "staging" ? 1 : 0
  name                 = "load_test"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "load_test_policy" {
  count      = var.env == "staging" ? 1 : 0
  repository = aws_ecr_repository.load_test_repository[0].name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"

      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }

      action = {
        type = "expire"
      }
    }]
  })
}
