#
# Database secrets
#

# This secret is legacy and should be removed once `database_connection_url` has fully replaced it
resource "aws_secretsmanager_secret" "database_url" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "server-database-url"
  description             = "Database URL used to connect to Postgres. This secret can be removed once we have migrated all services to Prisma where `database_connection_url` should be used instead."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgres://${var.rds_db_user}:${var.rds_db_password}@${aws_rds_cluster.forms.endpoint}:5432/${var.rds_db_name}"
}

resource "aws_secretsmanager_secret" "database_connection_url" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "database-connection-url"
  description             = "Database URL used to connect to Postgres. It handles SSL connection (if available) with no certificate verification (default behavior for many drivers)."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_connection_url" {
  secret_id     = aws_secretsmanager_secret.database_connection_url.id
  secret_string = "postgres://${var.rds_db_user}:${var.rds_db_password}@${aws_rds_cluster.forms.endpoint}:5432/${var.rds_db_name}"
}

resource "aws_secretsmanager_secret" "rds_connector" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "rds-connector"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_connector" {
  depends_on    = [aws_rds_cluster.forms]
  secret_id     = aws_secretsmanager_secret.rds_connector.id
  secret_string = "{\"username\": \"${var.rds_connector_db_user}\",\"password\": \"${var.rds_connector_db_password}\"}"
}
