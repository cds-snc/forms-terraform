resource "aws_ssm_parameter" "load_testing_form_id" {
  # checkov:skip=CKV_AWS_337: default service encryption key is acceptable
  name        = "/load-testing/form-id"
  description = "Form ID that will be used to generate, retrieve and confirm responses."
  type        = "SecureString"
  value       = var.load_testing_form_id
}

resource "aws_ssm_parameter" "load_testing_form_private_key" {
  # checkov:skip=CKV_AWS_337: default service encryption key is acceptable
  name        = "/load-testing/form-private-key"
  description = "Private key JSON of the form that will be used to authenticate the API requests.  This must be a key for the `/load-testing/form-id` form."
  type        = "SecureString"
  value       = var.load_testing_form_private_key
}

resource "aws_ssm_parameter" "load_testing_zitadel_app_private_key" {
  # checkov:skip=CKV_AWS_337: default service encryption key is acceptable
  name        = "/load-testing/zitadel-app-private-key"
  description = "Private key JSON of the Zitadel application to perform access token introspection requests."
  type        = "SecureString"
  value       = var.load_testing_zitadel_app_private_key
}

resource "aws_ssm_parameter" "load_testing_submit_form_server_action_id_key" {
  # checkov:skip=CKV_AWS_337: default service encryption key is acceptable
  name        = "/load-testing/submit-form-server-action-id"
  description = "NextJS server action identifier associated to 'submitForm' function."
  type        = "SecureString"
  value       = "TBD"
}
