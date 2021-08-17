locals {
  image_name = "form_viewer_${var.environment}"
}

# Ignore using global encryption key
#tfsec:ignore:AWS093
resource "aws_ecr_repository" "viewer_repository" {

  name = local.image_name

  #Ignore tag mutability for Staging
  image_tag_mutability = "MUTABLE" #tfsec:ignore:AWS078

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.viewer_repository.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

output "ecr_repository_url" {
  value = aws_ecr_repository.viewer_repository.repository_url
}
