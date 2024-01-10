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


}
