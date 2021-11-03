output "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN"
  value       = aws_kms_key.cloudwatch.arn
}

output "kms_key_dynamodb_arn" {
  description = "DynamoDB KMS key ARN"
  value       = aws_kms_key.dynamo_db.arn
}
