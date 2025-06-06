
// Create IAM role to access S3 bucket for GuardDuty
// Need to scan and add tags

resource "aws_guardduty_malware_protection_plan" "reliability_queue_storage" {
  role = aws_iam_role.guard_duty.arn

  protected_resource {
    s3_bucket {
      bucket_name = var.reliability_storage_id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }
}