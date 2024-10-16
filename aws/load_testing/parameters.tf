resource "aws_ssm_parameter" "load_testing_form_id" {
  name        = "/load-testing/form-id"
  description = "Form ID that will be used to generate, retrieve and confirm responses."
  type        = "SecureString"
  value       = var.load_testing_form_id
}

resource "aws_ssm_parameter" "load_testing_private_key_form" {
  name        = "/load-testing/private-api-key-form"
  description = "Private key JSON of the form that will be used to authenticate the API requests.  This must be a key for the `/load-testing/form-id` form."
  type        = "SecureString"
  value       = var.load_testing_private_key_form
}

resource "aws_ssm_parameter" "load_testing_private_key_app" {
  name        = "/load-testing/private-api-key-app"
  description = "Private key JSON used by the application to perform access token introspection requests."
  type        = "SecureString"
  value       = var.load_testing_private_key_app
}
