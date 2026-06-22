variable "aws_region" {
  description = "AWS region for primary resources"
  type        = string
  default     = "us-east-1"
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer (e.g. app/finapi-alb/0123456789abcdef)"
  type        = string
}

variable "notification_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in the CloudWatch log group"
  type        = number
  default     = 14
}

variable "estimated_charges_threshold" {
  description = "Billing threshold in USD that triggers the EstimatedCharges alarm"
  type        = number
  default     = 50
}

variable "monthly_budget_usd" {
  description = "Monthly AWS budget cap in USD"
  type        = number
  default     = 100
}
