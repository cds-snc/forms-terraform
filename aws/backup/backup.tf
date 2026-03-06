resource "aws_backup_vault" "forms" {
  name          = "gcforms_backup_vault"
}

resource "aws_backup_plan" "forms" {
  name = "gcforms_backup_plan"

  rule {
    rule_name                = "gcforms_backup_rule"
    target_vault_name        = aws_backup_vault.forms.name
    enable_continuous_backup = true
    # Daily at 4am UTC
    schedule = "cron(0 4 ? * * *)"


    lifecycle {
      delete_after = 30
    }
  }

}
# Only S3 resources that are tagged to backup
resource "aws_backup_selection" "s3" {
  iam_role_arn = aws_iam_role.forms_backup_role.arn
  name         = "gcforms_backup_s3"
  plan_id      = aws_backup_plan.forms.id
  resources    = ["arn:aws:s3:::*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/managed_backup"
      value = "true"
    }
  }

}

# All RDS clusters
resource "aws_backup_selection" "rds" {
  iam_role_arn = aws_iam_role.forms_backup_role.arn
  name         = "gcforms_backup_rds"
  plan_id      = aws_backup_plan.forms.id
  resources    = ["arn:aws:rds:${var.region}:${var.account_id}:cluster:*"]
}

# Only DynamoDB resources that are tagged to backup
resource "aws_backup_selection" "dynamodb" {
  iam_role_arn = aws_iam_role.forms_backup_role.arn
  name         = "gcforms_backup_dynamodb"
  plan_id      = aws_backup_plan.forms.id
  resources    = ["arn:aws:dynamodb:${var.region}:${var.account_id}:table/*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/managed_backup"
      value = "true"
    }
  }

}