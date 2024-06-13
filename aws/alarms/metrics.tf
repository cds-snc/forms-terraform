#
# Metrics that will be used to monitor the behaviour and health of the app
#
locals {
  healthcheck_metrics = [{
    # ECS: client
    name           = "ClientSubmitSuccess"
    pattern        = "Response submitted for Form ID"
    log_group_name = var.ecs_cloudwatch_log_group_name
    }, {
    name           = "ClientSubmitFailed"
    pattern        = "Attempted response submission for Form ID"
    log_group_name = var.ecs_cloudwatch_log_group_name
    }, {
    # Lambda: form-archiver
    name           = "FormArchiverSuccess"
    pattern        = "{$.status = \"success\"}"
    log_group_name = var.lambda_form_archiver_log_group_name
    }, {
    name           = "FormArchiverWarn"
    pattern        = "{$.level = \"warn\"}"
    log_group_name = var.lambda_form_archiver_log_group_name
    }, {
    name           = "FormArchiverFailed"
    pattern        = "{$.status = \"failed\"}"
    log_group_name = var.lambda_form_archiver_log_group_name
    }, {
    # Lambda: reliability
    name           = "ReliabilitySuccess"
    pattern        = "{$.status = \"success\"}"
    log_group_name = var.lambda_reliability_log_group_name
    }, {
    name           = "ReliabilityWarn"
    pattern        = "{$.level = \"warn\"}"
    log_group_name = var.lambda_reliability_log_group_name
    }, {
    name           = "ReliabilityFailed"
    pattern        = "{$.status = \"failed\"}"
    log_group_name = var.lambda_reliability_log_group_name
    }, {
    name           = "ReliabilityNotifySendSuccess"
    pattern        = "Successfully sent submission through GC Notify"
    log_group_name = var.lambda_reliability_log_group_name
    }, {
    name           = "ReliabilityNotifySendFailed"
    pattern        = "Failed to send submission through GC Notify"
    log_group_name = var.lambda_reliability_log_group_name
    }, {
    name           = "ReliabilityVaultSaveSuccess"
    pattern        = "Successfully saved submission to Vault"
    log_group_name = var.lambda_reliability_log_group_name
    }, {
    name           = "ReliabilityVaultSaveFailed"
    pattern        = "Failed to save submission to Vault"
    log_group_name = var.lambda_reliability_log_group_name
    }, {
    # Lambda: response-archiver
    name           = "ResponseArchiverSuccess"
    pattern        = "{$.status = \"success\"}"
    log_group_name = var.lambda_response_archiver_log_group_name
    }, {
    name           = "ResponseArchiverWarn"
    pattern        = "{$.level = \"warn\"}"
    log_group_name = var.lambda_response_archiver_log_group_name
    }, {
    name           = "ResponseArchiverFailed"
    pattern        = "{$.status = \"failed\"}"
    log_group_name = var.lambda_response_archiver_log_group_name
    }, {
    # Lambda: submission
    name           = "SubmissionSuccess"
    pattern        = "{$.status = \"success\"}"
    log_group_name = var.lambda_submission_log_group_name
    }, {
    name           = "SubmissionWarn"
    pattern        = "{$.level = \"warn\"}"
    log_group_name = var.lambda_submission_log_group_name
    }, {
    name           = "SubmissionFailed"
    pattern        = "{$.status = \"failed\"}"
    log_group_name = var.lambda_submission_log_group_name
    }, {

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
