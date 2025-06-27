resource "aws_lambda_function" "prisma_migration" {
  function_name = "prisma-migration"
  image_uri     = "${var.ecr_repository_lambda_urls["prisma-migration-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300
  memory_size   = 512

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
      PRISMA_S3_BUCKET_NAME = var.prisma_migration_storage_id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Prisma_Migration_Handler"
  }

  tracing_config {
    mode = "Active"
  }
}


/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "prisma_migration_handler" {
  name              = "/aws/lambda/Prisma_Migration_Handler"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
