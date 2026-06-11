# Get current AWS region
data "aws_region" "current" {}

# CloudWatch Dashboard with comprehensive metrics
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
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
          region = data.aws_region.current.name
          title  = "Application Load Balancer Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
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
          region = data.aws_region.current.name
          title  = "RDS Database Metrics"
        }
      },
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
          region = data.aws_region.current.name
          title  = "Critical Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query  = "fields @timestamp, @message | filter @message like /ERROR/ | stats count() as error_count by bin(5m)"
          region = data.aws_region.current.name
          title  = "Application Errors (5-min bins)"
        }
      }
    ]
  })
}

output "dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
  description = "URL to CloudWatch Dashboard"
}