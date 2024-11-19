output "lb_arn" {
  description = "Load balancer ARN"
  value       = aws_lb.form_viewer.arn
}

output "lb_arn_suffix" {
  description = "Load balancer ARN suffix"
  value       = aws_lb.form_viewer.arn_suffix
}

output "lb_https_listener_arn" {
  description = "Load balancer HTTPS listener ARN"
  value       = aws_lb_listener.form_viewer_https.arn
}

output "lb_target_group_1_arn" {
  description = "Load balancer target group 1 ARN"
  value       = aws_lb_target_group.form_viewer_1.arn
}

output "lb_target_group_1_arn_suffix" {
  description = "Load balancer target group 1 ARN suffix for use with CloudWatch Alarm"
  value       = aws_lb_target_group.form_viewer_1.arn_suffix
}

output "lb_target_group_2_arn_suffix" {
  description = "Load balancer target group 2 ARN suffix for use with CloudWatch Alarm"
  value       = aws_lb_target_group.form_viewer_2.arn_suffix
}

output "lb_target_group_1_name" {
  description = "Load balancer target group 1 name, used by CodeDeploy to alternate blue/green deployments"
  value       = aws_lb_target_group.form_viewer_1.name
}

output "lb_target_group_2_name" {
  description = "Load balancer target group 2 name, used by CodeDeploy to alternate blue/green deployments"
  value       = aws_lb_target_group.form_viewer_2.name
}

output "lb_target_group_api_arn" {
  description = "Load balancer target group ARN for the API"
  value       = aws_lb_target_group.forms_api.arn
}

output "lb_target_group_api_arn_suffix" {
  description = "Load balancer target group ARN suffix for the API"
  value       = aws_lb_target_group.forms_api.arn_suffix
}

output "kinesis_firehose_waf_logs_arn" {
  description = "Kinesis Firehose delivery stream ARN used to collect and write WAF ACL logs to an S3 bucket."
  value       = aws_kinesis_firehose_delivery_stream.firehose_waf_logs.arn
}

output "waf_ipv4_blocklist_arn" {
  description = "WAF ACL IPv4 blocklist"
  value       = module.waf_ip_blocklist.ipv4_blocklist_arn
}

output "waf_ipv4_lambda_cloudwatch_log_group_name" {
  description = "WAF ACL IP blocklist Lambda CloudWatch name"
  value       = module.waf_ip_blocklist.ipv4_lambda_cloudwatch_log_group_name
}