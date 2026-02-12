output "ecr_form_viewer_repository_name" {
  description = "Name of the Form viewer ECR repository"
  value       = aws_ecr_repository.viewer_repository.name
}

output "ecr_repository_url_form_viewer" {
  description = "URL of the Form viewer ECR repository"
  value       = aws_ecr_repository.viewer_repository.repository_url
}

output "ecr_repository_url_cognito_email_sender_lambda" {
  description = "URL of the Cognito Email Sender Lambda ECR"
  value       = aws_ecr_repository.lambda["cognito-email-sender-lambda"].repository_url
}

output "ecr_repository_url_cognito_pre_sign_up_lambda" {
  description = "URL of the Cognito Pre Sign Up Lambda ECR"
  value       = aws_ecr_repository.lambda["cognito-pre-sign-up-lambda"].repository_url
}

output "ecr_repository_url_load_testing_lambda" {
  description = "URL of the Load Testing Lambda ECR"
  value       = try(aws_ecr_repository.lambda["load-testing-lambda"].repository_url, null)
}


output "ecr_repository_url_notify_slack_lambda" {
  description = "URL of the Notify Slack Lambda ECR"
  value       = aws_ecr_repository.lambda["notify-slack-lambda"].repository_url
}

output "ecr_repository_url_idp" {
  description = "URL of the Zitadel IdP's ECR"
  value       = aws_ecr_repository.idp.repository_url
}

output "ecr_repository_url_idp_user_portal" {
  description = "URL of the Zitadel User Portal ECR"
  value       = aws_ecr_repository.idp_user_portal.repository_url
}

output "ecr_repository_url_api" {
  description = "URL of the Forms API's ECR"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_repository_lambda_urls" {
  description = "URL Map of the Lambda's ECR"
  value = var.env == "development" ? {
    for lambda_name, ecr_repository in aws_ecr_repository.lambda : lambda_name => replace(ecr_repository.repository_url, var.account_id, var.staging_account_id)
    } : {
    for lambda_name, ecr_repository in aws_ecr_repository.lambda : lambda_name => tostring(ecr_repository.repository_url)
  }
}
