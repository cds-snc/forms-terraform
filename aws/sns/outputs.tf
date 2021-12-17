output "sns_topic_alert_critical_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = aws_sns_topic.alert_critical.arn
}

output "sns_topic_alert_warning_arn" {
  description = "SNS topic ARN for warning alerts"
  value       = aws_sns_topic.alert_warning.arn
}

output "sns_topic_alert_ok_arn" {
  description = "SNS topic ARN for ok alerts"
  value       = aws_sns_topic.alert_ok.arn
}

output "sns_topic_alert_warning_us_east_arn" {
  description = "SNS topic ARN for warning alerts (US East)"
  value       = aws_sns_topic.alert_warning_us_east.arn
}

output "sns_topic_alert_ok_us_east_arn" {
  description = "SNS topic ARN for ok alerts (US East)"
  value       = aws_sns_topic.alert_ok_us_east.arn
}