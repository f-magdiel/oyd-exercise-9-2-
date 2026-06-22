variable "aws_region" {
  description = "AWS region where primary resources are deployed"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer used in CloudWatch dimensions"
  type        = string
}

variable "notification_email" {
  description = "Email address to receive alarm notifications via SNS"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain application logs in CloudWatch"
  type        = number
  default     = 14
}

variable "estimated_charges_threshold" {
  description = "USD threshold for the EstimatedCharges billing alarm"
  type        = number
  default     = 50
}

variable "monthly_budget_usd" {
  description = "Monthly AWS budget cap in USD for the Budgets guard"
  type        = number
  default     = 100
}
