resource "aws_cloudwatch_metric_alarm" "UnHealthyHostCount-TargetGroup1" {
  alarm_name          = "App-UnHealthyHostCount-TargetGroup1"
  alarm_description   = "App LB Warning - unhealthy host count >= 1 in a 1 minute period for TargetGroup1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1" # If there is at least one unhealthy host
  evaluation_periods  = "1" # Evaluate once
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"      # Every minute
  statistic           = "Maximum" # the highest value observed during the specified period
  treat_missing_data  = "breaching"
  dimensions = {
    LoadBalancer = aws_lb.form_viewer.arn_suffix
    TargetGroup  = aws_lb_target_group.form_viewer_1.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "UnHealthyHostCount-TargetGroup2" {
  alarm_name          = "App-UnHealthyHostCount-TargetGroup2"
  alarm_description   = "App LB Warning - unhealthy host count >= 1 in a 1 minute period for TargetGroup2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1" # If there is at least one unhealthy host
  evaluation_periods  = "1" # Evaluate once
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"      # Every minute
  statistic           = "Maximum" # the highest value observed during the specified period
  treat_missing_data  = "breaching"
  dimensions = {
    LoadBalancer = aws_lb.form_viewer.arn_suffix
    TargetGroup  = aws_lb_target_group.form_viewer_2.arn_suffix
  }
}
