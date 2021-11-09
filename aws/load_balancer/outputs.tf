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

output "lb_target_group_1_name" {
  description = "Load balancer target group 1 name, used by CodeDeploy to alternate blue/green deployments"
  value       = aws_lb_target_group.form_viewer_1.name
}

output "lb_target_group_2_name" {
  description = "Load balancer target group 2 name, used by CodeDeploy to alternate blue/green deployments"
  value       = aws_lb_target_group.form_viewer_2.name
}
