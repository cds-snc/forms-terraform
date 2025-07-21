resource "aws_ssm_parameter" "load_testing_zitadel_app_private_key" {
  # checkov:skip=CKV_AWS_337: default service encryption key is acceptable
  name        = "/load-testing/zitadel-app-private-key"
  description = "Private key JSON of the Zitadel application to perform access token introspection requests."
  type        = "SecureString"
  value       = var.load_testing_zitadel_app_private_key
}
