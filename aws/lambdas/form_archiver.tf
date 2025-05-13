#
# Archive form templates
#

resource "aws_lambda_function" "form_archiver" {
  function_name = "form-archiver"
  architectures = ["arm64"]
  image_uri     = "${var.ecr_repository_lambda_urls["form-archiver-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300

  lifecycle {
    ignore_changes = [image_uri]
  }

  dynamic "vpc_config" {
    for_each = local.vpc_config
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  environment {
    variables = {
      REGION    = var.region
      DB_ARN    = var.rds_cluster_arn
      DB_SECRET = var.database_secret_arn
      DB_NAME   = var.rds_db_name
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Archive_Form_Templates"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_form_archiver_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.form_archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.form_archiver_lambda_trigger.arn
}

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "archive_form_templates" {
  name              = "/aws/lambda/Archive_Form_Templates"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
