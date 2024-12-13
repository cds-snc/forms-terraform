resource "aws_route53_health_check" "lb_web_app_target_group_1" {
  reference_name                  = "LB Tar Group 1 health"
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.UnHealthyHostCount-TargetGroup1.alarm_name
  cloudwatch_alarm_region         = var.region
  insufficient_data_health_status = "Unhealthy"
}

resource "aws_route53_health_check" "lb_web_app_target_group_2" {
  reference_name                  = "LB Tar Group 2 health"
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.UnHealthyHostCount-TargetGroup2.alarm_name
  cloudwatch_alarm_region         = var.region
  insufficient_data_health_status = "Unhealthy"
}

# Due to our blue green deployment strategy, one of the Web App target groups is always going to be left empty and the associated alarm
# will be triggered because of that. This health check ensures that at least one target group is healthy. If not then we will be able to
# serve the maintenance page to our visitors.
resource "aws_route53_health_check" "lb_web_app_global_target_group" {
  reference_name         = "Active LB Tar Group health"
  type                   = "CALCULATED"
  child_health_threshold = 1
  child_healthchecks = [
    aws_route53_health_check.lb_web_app_target_group_1.id,
    aws_route53_health_check.lb_web_app_target_group_2.id
  ]
}
