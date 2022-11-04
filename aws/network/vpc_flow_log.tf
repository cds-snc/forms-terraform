#
# VPC Flow Logs:
# Capture network traffic over the VPC
#
resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = "arn:aws:s3:::${var.cbs_satellite_bucket_name}/vpc_flow_logs/"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.forms.id
  log_format           = "$${vpc-id} $${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${subnet-id} $${instance-id}"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Log group can be deleted 30 days after `terraform apply` as
# the retention period will have expired.
#
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "vpc_flow_logs"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 30

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
