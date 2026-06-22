output "dashboard_url" {
  description = "Direct link to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "log_group_name" {
  description = "Name of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "http_5xx_alarm_name" {
  description = "Name of the HTTP 5xx CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.http_5xx.alarm_name
}

output "latency_alarm_name" {
  description = "Name of the latency CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.latency.alarm_name
}
