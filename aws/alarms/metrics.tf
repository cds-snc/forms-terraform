#
# Metrics that will be used to monitor the behaviour and health of the app
#
locals {
  healthcheck_metrics = [{
    name           = "FormsClientSubmitSuccess"
    pattern        = "Response submitted for Form ID"
    log_group_name = var.ecs_cloudwatch_log_group_name
    }, {
    name           = "FormsClientSubmitFailed"
    pattern        = "Attempted response submission for Form ID"
    log_group_name = var.ecs_cloudwatch_log_group_name
  }]
}

resource "aws_cloudwatch_log_metric_filter" "healthcheck" {
  for_each = { for metric in local.healthcheck_metrics : metric.name => metric }

  name           = each.value.name
  pattern        = each.value.pattern
  log_group_name = each.value.log_group_name

  metric_transformation {
    name          = each.value.name
    namespace     = "forms"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}
