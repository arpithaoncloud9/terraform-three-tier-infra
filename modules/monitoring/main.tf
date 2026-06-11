# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-app-logs"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for system logs
resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/${var.project_name}-system-logs"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for setup logs
resource "aws_cloudwatch_log_group" "setup_logs" {
  name              = "/aws/ec2/${var.project_name}-setup-logs"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Stream for app logs
resource "aws_cloudwatch_log_stream" "app_stream" {
  name           = "app-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "CloudWatch Log Group name"
}

output "app_logs_group" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "App logs group"
}

output "system_logs_group" {
  value       = aws_cloudwatch_log_group.system_logs.name
  description = "System logs group"
}

output "setup_logs_group" {
  value       = aws_cloudwatch_log_group.setup_logs.name
  description = "Setup logs group"
}