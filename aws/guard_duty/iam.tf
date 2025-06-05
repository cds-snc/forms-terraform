#
# IAM - Forms GuardDuty Malware Protection role
#
resource "aws_iam_role" "guard_duty" {
  name               = "guard_duty"
  assume_role_policy = data.aws_iam_policy_document.guard_duty_assume_role.json
}

data "aws_iam_policy_document" "guard_duty_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["malware-protection-plan.guardduty.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy_attachment" "guard_duty" {
  role       = aws_iam_role.guard_duty.name
  policy_arn = aws_iam_policy.guard_duty.arn
}



resource "aws_iam_policy" "guard_duty" {
  name   = "guard_duty_s3_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.guard_duty.json
}

data "aws_iam_policy_document" "guard_duty" {

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:PutBucketNotification",
      "s3:GetBucketNotification",

    ]

    resources = [
      var.reliability_storage_arn,
      "${var.reliability_storage_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "events:PutRule",
      "events:DeleteRule",
      "events:PutTargets",
      "events:RemoveTargets"
    ]
    resources = [
      "arn:aws:events:${var.region}:${var.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
    ]

    condition {
      test     = "StringLike"
      variable = "events:ManagedBy"
      values   = ["malware-protection-plan.guardduty.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule"
    ]
    resources = [
      "arn:aws:events:${var.region}:${var.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
    ]
  }
}
