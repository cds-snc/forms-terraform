resource "aws_lambda_function" "deployment_script" {
  function_name = "deployment-script"
  image_uri     = "${var.ecr_repository_lambda_urls["deployment-script-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 600
  memory_size   = 1024

  lifecycle {
    ignore_changes = [image_uri]
  }

  // Even in development mode this lambda should be attached to the VPC in order to connecto the DB
  vpc_config {
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }

  environment {
    variables = {
      DB_URL_SECRET_ARN     = var.database_url_secret_arn
      DEPLOYMENT_S3_BUCKET_NAME = var.deployment_script_storage_id
      REDIS_URL = var.redis_url
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Deployment_Handler"
  }

  tracing_config {
    mode = "PassThrough"
  }
}


 resource "aws_cloudwatch_log_group" "deployment_script_handler" {
  name              = "/aws/lambda/Deployment_Handler"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
