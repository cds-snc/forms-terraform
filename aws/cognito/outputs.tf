output "cognito_endpoint_url" {
  description = "Endpoint name of the user pool."
  value       = aws_cognito_user_pool.forms.endpoint
}

output "cognito_client_id" {
  description = "Client ID of the forms user pool client."
  value       = aws_cognito_user_pool_client.forms.id
}