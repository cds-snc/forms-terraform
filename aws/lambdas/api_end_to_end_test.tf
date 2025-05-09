#
# API end to end test
#

resource "aws_lambda_function" "api_end_to_end_test" {
  function_name = "api-end-to-end-test"
  image_uri     = "${var.ecr_repository_lambda_urls["api-end-to-end-test-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300

  vpc_config {
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      IDP_URL                = "http://${var.ecs_idp_service_name}.${var.service_discovery_private_dns_namespace_ecs_local_name}:${var.ecs_idp_service_port}"
      IDP_PROJECT_IDENTIFIER = var.idp_project_identifier
      API_URL                = "http://${var.ecs_api_service_name}.${var.service_discovery_private_dns_namespace_ecs_local_name}:${var.ecs_api_service_port}"
      FORM_ID                = var.api_end_to_end_test_form_identifier
      API_PRIVATE_KEY        = var.api_end_to_end_test_form_api_private_key
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/API_End_To_End_Test"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_cloudwatch_log_group" "api_end_to_end_test" {
  name              = "/aws/lambda/API_End_To_End_Test"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_api_end_to_end_test_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_end_to_end_test.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.api_end_to_end_test_lambda_trigger.arn
}
