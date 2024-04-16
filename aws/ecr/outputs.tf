output "ecr_repository_url_form_viewer" {
  description = "URL of the Form viewer ECR"
  value       = aws_ecr_repository.viewer_repository.repository_url
}

output "ecr_repository_url_audit_logs_lambda" {
  description = "URL of the Audit Logs Lambda ECR"
  value       = aws_ecr_repository.audit_logs_lambda.repository_url
}

output "ecr_repository_url_audit_logs_archiver_lambda" {
  description = "URL of the Audit Logs Archiver Lambda ECR"
  value       = aws_ecr_repository.audit_logs_archiver_lambda.repository_url
}

output "ecr_repository_url_form_archiver_lambda" {
  description = "URL of the Form Archiver Lambda ECR"
  value       = aws_ecr_repository.form_archiver_lambda.repository_url
}

output "ecr_repository_url_nagware_lambda" {
  description = "URL of the Nagware Lambda ECR"
  value       = aws_ecr_repository.nagware_lambda.repository_url
}

output "ecr_repository_url_reliability_lambda" {
  description = "URL of the Reliability Lambda ECR"
  value       = aws_ecr_repository.reliability_lambda.repository_url
}

output "ecr_repository_url_reliability_dlq_consumer_lambda" {
  description = "URL of the Reliability DLQ Consumer Lambda ECR"
  value       = aws_ecr_repository.reliability_dlq_consumer_lambda.repository_url
}

output "ecr_repository_url_response_archiver_lambda" {
  description = "URL of the Response Archiver Lambda ECR"
  value       = aws_ecr_repository.response_archiver_lambda.repository_url
}

output "ecr_repository_url_submission_lambda" {
  description = "URL of the Submission Lambda ECR"
  value       = aws_ecr_repository.submission_lambda.repository_url
}

output "ecr_repository_url_vault_integrity_lambda" {
  description = "URL of the Vault Integrity Lambda ECR"
  value       = aws_ecr_repository.vault_integrity_lambda.repository_url
}

output "ecr_repository_url_notify_slack_lambda" {
  description = "URL of the Notify Slack Lambda ECR"
  value       = aws_ecr_repository.notify_slack_lambda.repository_url
}

output "ecr_repository_url_cognito_email_sender_lambda" {
  description = "URL of the Cognito Email Sender Lambda ECR"
  value       = aws_ecr_repository.cognito_email_sender_lambda.repository_url
}

output "ecr_repository_url_cognito_pre_sign_up_lambda" {
  description = "URL of the Cognito Pre Sign Up Lambda ECR"
  value       = aws_ecr_repository.cognito_pre_sign_up_lambda.repository_url
}

output "ecr_repository_url_load_test" {
  description = "URL of the Form viewer ECR"
  value       = length(aws_ecr_repository.load_test_repository) > 0 ? aws_ecr_repository.load_test_repository[0].repository_url : ""
}