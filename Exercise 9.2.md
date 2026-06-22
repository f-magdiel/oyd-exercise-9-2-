# **Exercise 9.2 \- Dashboards**

**Course:** Optimizaciones y Desempeño — Cloud Deployment Automation  
**Session:** 9 — June 18, 2026  
**Time allowed:** 30 minutes  
**Submission:** Initialize a new repository called oyd-exercise-9-2 and commit/push everything into it. Submit the repository URL only.

# Context

FinAPI's observability module is in place: log group, SNS topic, error-rate alarm, latency alarm, EstimatedCharges alarm, and a budget guard. The on-call team now wants a single CloudWatch dashboard so they can see request volume, error rate, and cost alarm state in one view — without navigating across multiple CloudWatch pages.

Your starter project is a complete copy of the Exercise 9.1 end state: the observability module already contains all alarms, the SNS topic, and the log group. Your job is to add the dashboard to the existing module without breaking any existing resources.

Key starter files for reference:

### modules/observability/main.tf (existing content — do not remove)

terraform {  
  required\_providers {  
    aws \= {  
      source                \= "hashicorp/aws"  
      configuration\_aliases \= \[aws.us\_east\_1\]  
    }  
  }  
}

resource "aws\_cloudwatch\_log\_group" "app" {  
  name              \= "/finapi/dev"  
  retention\_in\_days \= var.log\_retention\_days  
}

resource "aws\_sns\_topic" "alerts" {  
  name \= "finapi-alerts"  
}

resource "aws\_sns\_topic\_subscription" "email" {  
  topic\_arn \= aws\_sns\_topic.alerts.arn  
  protocol  \= "email"  
  endpoint  \= var.notification\_email  
}

resource "aws\_cloudwatch\_metric\_alarm" "http\_5xx" {  
  alarm\_name          \= "finapi-http-5xx"  
  namespace           \= "AWS/ApplicationELB"  
  metric\_name         \= "HTTPCode\_Target\_5XX\_Count"  
  dimensions          \= { LoadBalancer \= var.alb\_arn\_suffix }  
  statistic           \= "Sum"  
  period              \= 60  
  evaluation\_periods  \= 2  
  threshold           \= 5  
  comparison\_operator \= "GreaterThanOrEqualToThreshold"  
  treat\_missing\_data  \= "notBreaching"  
  alarm\_actions       \= \[aws\_sns\_topic.alerts.arn\]  
  ok\_actions          \= \[aws\_sns\_topic.alerts.arn\]  
}

resource "aws\_cloudwatch\_metric\_alarm" "latency" {  
  alarm\_name          \= "finapi-latency"  
  namespace           \= "AWS/ApplicationELB"  
  metric\_name         \= "TargetResponseTime"  
  dimensions          \= { LoadBalancer \= var.alb\_arn\_suffix }  
  statistic           \= "Average"  
  period              \= 60  
  evaluation\_periods  \= 2  
  threshold           \= 1  
  comparison\_operator \= "GreaterThanOrEqualToThreshold"  
  treat\_missing\_data  \= "notBreaching"  
  alarm\_actions       \= \[aws\_sns\_topic.alerts.arn\]  
  ok\_actions          \= \[aws\_sns\_topic.alerts.arn\]  
}

resource "aws\_cloudwatch\_metric\_alarm" "estimated\_charges" {  
  provider            \= aws.us\_east\_1  
  alarm\_name          \= "finapi-estimated-charges"  
  namespace           \= "AWS/Billing"  
  metric\_name         \= "EstimatedCharges"  
  dimensions          \= { Currency \= "USD" }  
  statistic           \= "Maximum"  
  period              \= 86400  
  evaluation\_periods  \= 1  
  threshold           \= var.estimated\_charges\_threshold  
  comparison\_operator \= "GreaterThanOrEqualToThreshold"  
  alarm\_actions       \= \[aws\_sns\_topic.alerts.arn\]  
}

resource "aws\_budgets\_budget" "monthly" {  
  budget\_type  \= "COST"  
  time\_unit    \= "MONTHLY"  
  limit\_amount \= tostring(var.monthly\_budget\_usd)  
  limit\_unit   \= "USD"

  notification {  
    threshold                  \= 80  
    threshold\_type             \= "PERCENTAGE"  
    notification\_type          \= "ACTUAL"  
    comparison\_operator        \= "GREATER\_THAN"  
    subscriber\_email\_addresses \= \[var.notification\_email\]  
  }  
}

\# Task 1: add aws\_cloudwatch\_dashboard here

# Setup

## Prerequisites

* AWS CLI configured with valid credentials  
* Terraform \>= 1.6 installed  
* Your team's ALB ARN suffix and a confirmed SNS email subscription (same values from Exercise 9.1 — you can reuse your dev.tfvars)  
* curl or Apache Bench (ab) available on your machine to generate test traffic

## Repository structure

oyd-exercise-9-2/  
├── versions.tf  
├── main.tf  
├── variables.tf  
├── outputs.tf  
├── envs/  
│   └── dev/  
│       └── dev.tfvars  
├── evidence/  
│   └── dashboard.png     ← required screenshot  
└── modules/  
    └── observability/  
        ├── main.tf       ← add dashboard here (keep all existing resources)  
        ├── variables.tf  
        └── outputs.tf    ← add dashboard\_url output here

# Tasks

## Task 1 — Add the dashboard resource

In modules/observability/main.tf, add an aws\_cloudwatch\_dashboard resource below the existing resources. Use dashboard\_body \= jsonencode({...}) — no heredoc strings are allowed.

The jsonencode() call must produce a valid CloudWatch dashboard body. The outer structure is:

{  
  "widgets": \[  
    { ... },  
    { ... },  
    { ... }  
  \]  
}

In Terraform HCL, this looks like:

resource "aws\_cloudwatch\_dashboard" "main" {  
  dashboard\_name \= "finapi-dashboard"  
  dashboard\_body \= jsonencode({  
    widgets \= \[  
      \# Task 2: add three widget objects here  
    \]  
  })  
}

## Task 2 — Implement three widgets

Add at least three widget objects inside the widgets array. All metric widgets must reference Terraform expressions — no hardcoded ARN strings or account IDs.

1. Widget 1 — ALB request count. Type "metric", namespace "AWS/ApplicationELB", metric name "RequestCount", dimension key "LoadBalancer" with value \= var.alb\_arn\_suffix. Use stat \= "Sum", period \= 300\.  
2. Widget 2 — HTTP 5xx count. Same namespace and dimension. Metric name "HTTPCode\_Target\_5XX\_Count". stat \= "Sum", period \= 300\.  
3. Widget 3 — your team's choice. Valid options: a TargetResponseTime metric widget (same namespace/dimension), an alarm widget referencing aws\_cloudwatch\_metric\_alarm.http\_5xx.alarm\_name, or a text widget with a status note. The widget must be valid CloudWatch dashboard JSON.

Each metric widget follows this shape:

{  
  type   \= "metric"  
  width  \= 8  
  height \= 6  
  properties \= {  
    title  \= "Request Count"  
    stat   \= "Sum"  
    period \= 300  
    metrics \= \[  
      \["AWS/ApplicationELB", "RequestCount",  
        "LoadBalancer", var.alb\_arn\_suffix\]  
    \]  
  }  
}

## Task 3 — Expose the dashboard URL as an output

In modules/observability/outputs.tf, add:

output "dashboard\_url" {  
  description \= "Direct link to the CloudWatch dashboard"  
  value       \= "https://${var.aws\_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws\_region}\#dashboards:name=${aws\_cloudwatch\_dashboard.main.dashboard\_name}"  
}

In root outputs.tf, expose it:

output "dashboard\_url" {  
  value \= module.observability.dashboard\_url  
}

## Task 4 — Apply and generate traffic

Run terraform apply, then generate traffic against your ALB so at least one metric widget shows data:

terraform apply \-var-file="envs/dev/dev.tfvars"

\# Generate 30 requests against your ALB (replace with your ALB DNS name)  
for i in $(seq 1 30); do curl \-s \-o /dev/null http://\<YOUR-ALB-DNS\>/; done

Wait 2–3 minutes for CloudWatch to ingest the data. Then open the dashboard URL:

terraform output dashboard\_url

Confirm the dashboard loads and at least one widget shows a data point. Take a screenshot and save it as evidence/dashboard.png in your repository.

# Acceptance Criteria

* modules/observability/main.tf contains an aws\_cloudwatch\_dashboard resource alongside all pre-existing alarm and SNS resources  
* dashboard\_body uses jsonencode() — no heredoc strings anywhere in the file  
* The dashboard has at least three widgets; all metric widgets reference Terraform expressions (var.alb\_arn\_suffix, resource attributes) rather than hardcoded IDs  
* terraform apply completes without errors  
* terraform output dashboard\_url prints a valid URL  
* Dashboard is visible in the CloudWatch console and at least one widget shows data — saved as evidence/dashboard.png in the repository  
* Repository is named oyd-exercise-9-2 and the URL is submitted

