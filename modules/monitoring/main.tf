# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-app-logs"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "app_stream" {
  name           = "app-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "CloudWatch Log Group name"
}