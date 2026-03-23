resource "aws_codestarconnections_connection" "this" {
  name          = "${var.app_name}-GitHub"
  provider_type = "GitHub"
}
