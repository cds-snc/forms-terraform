resource "aws_glue_security_configuration" "encryption_at_rest" {
  name = "encryption-at-rest"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = aws_kms_key.aws_glue.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = aws_kms_key.aws_glue.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-S3"
    }
  }
}

#
# RDS Usage Report
#
resource "aws_glue_crawler" "forms_rds_data" {
  name          = "RDS Usage Report"
  description   = "Classify the Forms RDS data"
  database_name = "rds_db_name"
  table_prefix  = "rds_report_"

  role                   = aws_iam_role.glue_crawler.arn
  security_configuration = aws_glue_security_configuration.encryption_at_rest.name

  s3_target {
    path = "s3://${var.datalake_bucket_name}/operations/aws/rds-usage-report"
  }

  configuration = jsonencode(
    {
      CrawlerOutput = {
        Tables = {
          TableThreshold = 2
        }
      }
      CreatePartitionIndex = true
      Version              = 1
  })

  schedule = "cron(00 7 1 * ? *)" # Create the new month's partition key
}