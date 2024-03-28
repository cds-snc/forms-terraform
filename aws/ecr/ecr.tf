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
# Elastic Container Registry
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
