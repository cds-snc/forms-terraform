resource "aws_backup_vault" "forms" {
  name          = "gcforms_backup_vault"
  force_destroy = true
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

resource "aws_backup_selection" "forms" {
  iam_role_arn = aws_iam_role.forms_backup_role.arn
  name         = "gcforms_backup_selection"
  plan_id      = aws_backup_plan.forms.id
  resources = ["arn:aws:dynamodb:${var.region}:${var.account_id}:table/*", "arn:aws:rds:${var.region}:${var.account_id}:cluster:*", "arn:aws:s3:::*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/managed_backup"
      value = "true"
    }
  }

}