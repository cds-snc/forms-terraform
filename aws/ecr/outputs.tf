output "ecr_repository_url" {
  description = "URL of the Form viewer ECR"
  value       = aws_ecr_repository.viewer_repository.repository_url
}
