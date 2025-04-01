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
  database_name = aws_glue_catalog_database.rds_db_catalog.name
  table_prefix  = "rds_report_"

  role                   = aws_iam_role.glue_crawler.arn
  security_configuration = aws_glue_security_configuration.encryption_at_rest.name

  s3_target {
    path = "s3://${var.datalake_bucket_name}/platform/gc-forms/processed-data/template/"
  }

  s3_target {
    path = "s3://${var.datalake_bucket_name}/platform/gc-forms/processed-data/user/"
  }

  s3_target {
    path = "s3://${var.datalake_bucket_name}/platform/gc-forms/processed-data/templateToUser/"
  }

  s3_target {
    path = "s3://${var.datalake_bucket_name}/platform/gc-forms/processed-data/submissions/"
  }

  configuration = jsonencode(
    {
      CrawlerOutput = {
        Tables = {
          TableThreshold = 4
        }
      }
      CreatePartitionIndex = true
      Version              = 1
  })

  schedule = "cron(00 7 1 * ? *)" # Create the new month's partition key
}

# Historical Data
resource "aws_glue_crawler" "forms_historical_data" {
  name          = "Historical Usage Report"
  description   = "Classify the Forms Historical data"
  database_name = "rds_db_catalog"
  table_prefix  = "rds_report_"

  role                   = aws_iam_role.glue_crawler.arn
  security_configuration = aws_glue_security_configuration.encryption_at_rest.name

  s3_target {
    path = "s3://${var.datalake_bucket_name}/platform/gc-forms/historical-data"
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
}