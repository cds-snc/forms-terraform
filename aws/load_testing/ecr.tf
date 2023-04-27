#
# Elastic Container Registry
# Holds the Load Balancer image used by the Lambda
#
resource "aws_ecr_repository" "load_test_repository" {
  name                 = "load_test"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.load_test_repository.name
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
