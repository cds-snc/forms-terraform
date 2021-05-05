###
# AWS Secret Manager - Forms
###

resource "aws_secretsmanager_secret" "notify_api_key" {
  name                    = "notify_api_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "notify_api_key" {
  secret_id     = aws_secretsmanager_secret.notify_api_key.id
  secret_string = var.ecs_secret_notify_api_key
}

resource "aws_secretsmanager_secret" "google_client_id" {
  name                    = "google_client_id"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "google_client_id" {
  secret_id     = aws_secretsmanager_secret.google_client_id.id
  secret_string = var.ecs_secret_google_client_id
}

resource "aws_secretsmanager_secret" "google_client_secret" {
  name                    = "google_client_secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "google_client_secret" {
  secret_id     = aws_secretsmanager_secret.google_client_secret.id
  secret_string = var.ecs_secret_google_client_secret
}

resource "aws_secretsmanager_secret" "database_url" {
  name                    = "server-database-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgres://${var.rds_db_user}:${var.rds_db_password}@${aws_rds_cluster.forms.endpoint}:5432/${var.rds_db_name}"
}