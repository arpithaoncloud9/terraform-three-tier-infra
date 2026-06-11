# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-app-logs"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "app_stream" {
  name           = "app-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
}

# IAM Policy for EC2 to write logs to CloudWatch
resource "aws_iam_policy" "ec2_cloudwatch_logs" {
  name        = "${var.project_name}-ec2-cloudwatch-logs-policy"
  description = "Allow EC2 to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "${aws_cloudwatch_log_group.app_logs.arn}:*"
      }
    ]
  })
}

# Attach policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logs" {
  role       = var.ec2_role_name
  policy_arn = aws_iam_policy.ec2_cloudwatch_logs.arn
}

# IAM Policy for custom metrics
resource "aws_iam_policy" "ec2_cloudwatch_metrics" {
  name        = "${var.project_name}-ec2-cloudwatch-metrics-policy"
  description = "Allow EC2 to put custom metrics to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach metrics policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_metrics" {
  role       = var.ec2_role_name
  policy_arn = aws_iam_policy.ec2_cloudwatch_metrics.arn
}

# Output log group name for use in other modules
output "log_group_name" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "CloudWatch Log Group name"
}