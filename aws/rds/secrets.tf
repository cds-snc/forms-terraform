#
# Database secrets
#
resource "aws_secretsmanager_secret" "database_url" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "server-database-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgres://${var.rds_db_user}:${var.rds_db_password}@${aws_rds_cluster.forms.endpoint}:5432/${var.rds_db_name}"
}

resource "aws_secretsmanager_secret" "database_secret" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "database-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_secret" {
  depends_on    = [aws_rds_cluster.forms]
  secret_id     = aws_secretsmanager_secret.database_secret.id
  secret_string = "{\"dbInstanceIdentifier\": \"${var.rds_name}-cluster\",\"engine\": \"${aws_rds_cluster.forms.engine}\",\"host\": \"${aws_rds_cluster.forms.endpoint}\",\"port\": ${aws_rds_cluster.forms.port},\"resourceId\": \"${aws_rds_cluster.forms.cluster_resource_id}\",\"username\": \"${var.rds_db_user}\",\"password\": \"${var.rds_db_password}\"}"
}
