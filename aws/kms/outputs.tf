output "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN"
  value       = aws_kms_key.cloudwatch.arn
}

output "kms_key_cloudwatch_us_east_arn" {
  description = "CloudWatch KMS key ARN in us-east-1"
  value       = aws_kms_key.cloudwatch_us_east.arn
}

output "kms_key_dynamodb_arn" {
  description = "DynamoDB KMS key ARN"
  value       = aws_kms_key.dynamo_db.arn
}
