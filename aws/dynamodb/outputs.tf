output "dynamodb_relability_queue_arn" {
  description = "Reliability queue DynamodDB table ARN"
  value       = aws_dynamodb_table.reliability_queue.arn
}

output "dynamodb_vault_arn" {
  description = "Vault DynamodDB table ARN"
  value       = aws_dynamodb_table.vault.arn
}
