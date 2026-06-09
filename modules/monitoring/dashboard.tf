resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: ALB Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", label = "Response Time" }],
            ["...", "RequestCount", { stat = "Sum", label = "Request Count" }],
            ["...", "HealthyHostCount", { stat = "Average", label = "Healthy Hosts" }],
            ["...", "UnHealthyHostCount", { stat = "Average", label = "Unhealthy Hosts" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Application Load Balancer Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },

      # Widget 2: EC2 CPU
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          annotations = {
            horizontal = [
              {
                value = 75
                label = "Scale Threshold"
              }
            ]
          }
        }
      },

      # Widget 3: RDS Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "CPU" }],
            ["...", "DatabaseConnections", { stat = "Average", label = "Connections" }],
            ["...", "FreeableMemory", { stat = "Average", label = "Free Memory (bytes)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Database Metrics"
        }
      },

      # Widget 4: Recent Alarms
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount"],
            ["AWS/EC2", "CPUUtilization"],
            ["AWS/RDS", "CPUUtilization"]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Critical Metrics"
        }
      },

      # Widget 5: Log Groups
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | filter @message like /ERROR/ | stats count() as error_count by bin(5m)"
          region  = var.aws_region
          title   = "Application Errors (5-min bins)"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

output "dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
  description = "URL to CloudWatch Dashboard"
}