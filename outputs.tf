output "dashboard_url" {
  description = "Direct link to the FinAPI CloudWatch dashboard"
  value       = module.observability.dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = module.observability.sns_topic_arn
}

output "log_group_name" {
  description = "Name of the application CloudWatch log group"
  value       = module.observability.log_group_name
}
