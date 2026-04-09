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

resource "aws_secretsmanager_secret" "postgres_json_connection_object" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "postgres-json-connection-object"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "postgres_json_connection_object" {
  secret_id = aws_secretsmanager_secret.postgres_json_connection_object.id
  secret_string = jsonencode({
    host : aws_rds_cluster.forms.endpoint
    port : 5432
    username : var.rds_db_user
    password : var.rds_db_password
    database : var.rds_db_name
    ssl : "prefer"
  })

  depends_on = [aws_rds_cluster.forms]
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
