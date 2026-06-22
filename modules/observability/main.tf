terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# ---------------------------------------------------------------------------
# Log Group
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "app" {
  name              = "/finapi/dev"
  retention_in_days = var.log_retention_days
}

# ---------------------------------------------------------------------------
# SNS Topic & Email Subscription
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "finapi-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ---------------------------------------------------------------------------
# Alarms
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "finapi-http-5xx"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "finapi-latency"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  provider            = aws.us_east_1
  alarm_name          = "finapi-estimated-charges"
  namespace           = "AWS/Billing"
  metric_name         = "EstimatedCharges"
  dimensions          = { Currency = "USD" }
  statistic           = "Maximum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = var.estimated_charges_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_budgets_budget" "monthly" {
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"

  notification {
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    subscriber_email_addresses = [var.notification_email]
  }
}

# ---------------------------------------------------------------------------
# Task 1: CloudWatch Dashboard
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "finapi-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1 — ALB Request Count
      {
        type   = "metric"
        width  = 8
        height = 6
        properties = {
          title  = "Request Count"
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.alb_arn_suffix
            ]
          ]
        }
      },

      # Widget 2 — HTTP 5xx Error Count
      {
        type   = "metric"
        width  = 8
        height = 6
        properties = {
          title  = "HTTP 5xx Errors"
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix
            ]
          ]
        }
      },

      # Widget 3 — Target Response Time (Latency)
      {
        type   = "metric"
        width  = 8
        height = 6
        properties = {
          title  = "Target Response Time (p99)"
          stat   = "p99"
          period = 300
          view   = "timeSeries"
          region = var.aws_region
          annotations = {
            horizontal = [
              {
                label = "Latency Threshold"
                value = 1
                color = "#ff6961"
              }
            ]
          }
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.alb_arn_suffix
            ]
          ]
        }
      }
    ]
  })
}
