output "ecr_repository_url_form_viewer" {
  description = "URL of the Form viewer ECR"
  value       = aws_ecr_repository.viewer_repository.repository_url
}

output "ecr_repository_url_load_test" {
  description = "URL of the Form viewer ECR"
  value       = aws_ecr_repository.load_test_repository.repository_url
}