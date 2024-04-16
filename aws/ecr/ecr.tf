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

#
# Holds the containerized Lambda functions
#

resource "aws_ecr_repository" "audit_logs_lambda" {
  name                 = "audit-logs-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "audit_logs_lambda" {
  repository = aws_ecr_repository.audit_logs_lambda.name

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

resource "aws_ecr_repository" "audit_logs_archiver_lambda" {
  name                 = "audit-logs-archiver-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "audit_logs_archiver_lambda" {
  repository = aws_ecr_repository.audit_logs_archiver_lambda.name

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

resource "aws_ecr_repository" "form_archiver_lambda" {
  name                 = "form-archiver-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "form_archiver_lambda" {
  repository = aws_ecr_repository.form_archiver_lambda.name

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

resource "aws_ecr_repository" "nagware_lambda" {
  name                 = "nagware-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "nagware_lambda" {
  repository = aws_ecr_repository.nagware_lambda.name

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

resource "aws_ecr_repository" "reliability_lambda" {
  name                 = "reliability-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "reliability_lambda" {
  repository = aws_ecr_repository.reliability_lambda.name

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

resource "aws_ecr_repository" "reliability_dlq_consumer_lambda" {
  name                 = "reliability-dlq-consumer-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "reliability_dlq_consumer_lambda" {
  repository = aws_ecr_repository.reliability_dlq_consumer_lambda.name

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

resource "aws_ecr_repository" "response_archiver_lambda" {
  name                 = "response-archiver-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "response_archiver_lambda" {
  repository = aws_ecr_repository.response_archiver_lambda.name

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

resource "aws_ecr_repository" "submission_lambda" {
  name                 = "submission-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "submission_lambda" {
  repository = aws_ecr_repository.submission_lambda.name

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

resource "aws_ecr_repository" "vault_integrity_lambda" {
  name                 = "vault-integrity-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "vault_integrity_lambda" {
  repository = aws_ecr_repository.vault_integrity_lambda.name

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

resource "aws_ecr_repository" "notify_slack_lambda" {
  name                 = "notify-slack-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "notify_slack_lambda" {
  repository = aws_ecr_repository.notify_slack_lambda.name

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

resource "aws_ecr_repository" "cognito_email_sender_lambda" {
  name                 = "cognito-email-sender-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "cognito_email_sender_lambda" {
  repository = aws_ecr_repository.cognito_email_sender_lambda.name

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

resource "aws_ecr_repository" "cognito_pre_sign_up_lambda" {
  name                 = "cognito-pre-sign-up-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "cognito_pre_sign_up_lambda" {
  repository = aws_ecr_repository.cognito_pre_sign_up_lambda.name

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
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }

      action = {
        type = "expire"
      }
    }]
  })
}
