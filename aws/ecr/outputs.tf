output "ecr_repository_url_form_viewer" {
  description = "URL of the Form viewer ECR"
  value       = aws_ecr_repository.viewer_repository.repository_url
}

output "ecr_repository_url_audit_logs_lambda" {
  description = "URL of the Audit Logs Lambda ECR"
  value       = aws_ecr_repository.lambda["audit-logs-lambda"].repository_url
}

output "ecr_repository_url_audit_logs_archiver_lambda" {
  description = "URL of the Audit Logs Archiver Lambda ECR"
  value       = aws_ecr_repository.lambda["audit-logs-archiver-lambda"].repository_url
}

output "ecr_repository_url_cognito_email_sender_lambda" {
  description = "URL of the Cognito Email Sender Lambda ECR"
  value       = aws_ecr_repository.lambda["cognito-email-sender-lambda"].repository_url
}

output "ecr_repository_url_cognito_pre_sign_up_lambda" {
  description = "URL of the Cognito Pre Sign Up Lambda ECR"
  value       = aws_ecr_repository.lambda["cognito-pre-sign-up-lambda"].repository_url
}

output "ecr_repository_url_form_archiver_lambda" {
  description = "URL of the Form Archiver Lambda ECR"
  value       = aws_ecr_repository.lambda["form-archiver-lambda"].repository_url
}

output "ecr_repository_url_load_testing_lambda" {
  description = "URL of the Load Testing Lambda ECR"
  value       = aws_ecr_repository.lambda["load-testing-lambda"].repository_url
}

output "ecr_repository_url_nagware_lambda" {
  description = "URL of the Nagware Lambda ECR"
  value       = aws_ecr_repository.lambda["nagware-lambda"].repository_url
}

output "ecr_repository_url_notify_slack_lambda" {
  description = "URL of the Notify Slack Lambda ECR"
  value       = aws_ecr_repository.lambda["notify-slack-lambda"].repository_url
}

output "ecr_repository_url_reliability_lambda" {
  description = "URL of the Reliability Lambda ECR"
  value       = aws_ecr_repository.lambda["reliability-lambda"].repository_url
}

output "ecr_repository_url_reliability_dlq_consumer_lambda" {
  description = "URL of the Reliability DLQ Consumer Lambda ECR"
  value       = aws_ecr_repository.lambda["reliability-dlq-consumer-lambda"].repository_url
}

output "ecr_repository_url_response_archiver_lambda" {
  description = "URL of the Response Archiver Lambda ECR"
  value       = aws_ecr_repository.lambda["response-archiver-lambda"].repository_url
}

output "ecr_repository_url_submission_lambda" {
  description = "URL of the Submission Lambda ECR"
  value       = aws_ecr_repository.lambda["submission-lambda"].repository_url
}

output "ecr_repository_url_vault_integrity_lambda" {
  description = "URL of the Vault Integrity Lambda ECR"
  value       = aws_ecr_repository.lambda["vault-integrity-lambda"].repository_url
}

output "ecr_repository_url_idp" {
  description = "URL of the Zitadel IdP's ECR"
  value       = aws_ecr_repository.idp.repository_url
}

output "ecr_repository_url_api" {
  description = "URL of the Forms API's ECR"
  value       = aws_ecr_repository.api.repository_url
}
