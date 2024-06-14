resource "aws_cloudwatch_dashboard" "forms_service_health" {
  dashboard_name = "Forms-Service-Health"
  dashboard_body = jsonencode(templatefile("${path.module}/dashboards/forms_service_health.tmpl.json", {
    alarm_ecs_cpu_utilization_warn          = aws_cloudwatch_metric_alarm.forms_cpu_utilization_high_warn.arn,
    alarm_ecs_memory_utilization_warn       = aws_cloudwatch_metric_alarm.forms_memory_utilization_high_warn.arn,
    alarm_lb_response_5xx_warn              = aws_cloudwatch_metric_alarm.ELB_5xx_error_warn.arn,
    alarm_lb_response_time_warn             = aws_cloudwatch_metric_alarm.response_time_warn.arn,
    alarm_lb_unhealth_host_count_tg1        = aws_cloudwatch_metric_alarm.UnHealthyHostCount-TargetGroup1.arn,
    alarm_lb_unhealth_host_count_tg2        = aws_cloudwatch_metric_alarm.UnHealthyHostCount-TargetGroup2.arn,
    alarm_reliability_deadletter_queue      = aws_cloudwatch_metric_alarm.reliability_dead_letter_queue_warn.arn,
    lb_arn_suffix                           = var.lb_arn_suffix,
    ecs_cloudwatch_log_group_name           = var.ecs_cloudwatch_log_group_name,
    ecs_cluster_name                        = var.ecs_cluster_name,
    ecs_service_name                        = var.ecs_service_name,
    lambda_nagware_log_group_name           = var.lambda_nagware_log_group_name,
    lambda_reliability_log_group_name       = var.lambda_reliability_log_group_name,
    lambda_response_archiver_log_group_name = var.lambda_response_archiver_log_group_name,
    lambda_submission_log_group_name        = var.lambda_submission_log_group_name,
    lambda_vault_integrity_log_group_name   = var.lambda_vault_integrity_log_group_name,
    rds_cluster_identifier                  = var.rds_cluster_identifier,
    region                                  = var.region
  }))
}
