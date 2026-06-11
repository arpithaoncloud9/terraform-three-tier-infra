# SNS Topic for critical alerts
resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-critical-alerts"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# SNS Topic for warning alerts
resource "aws_sns_topic" "warning_alerts" {
  name = "${var.project_name}-warning-alerts"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Email subscription for critical alerts
resource "aws_sns_topic_subscription" "critical_email" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  depends_on = [aws_sns_topic.critical_alerts]
}

# Email subscription for warning alerts
resource "aws_sns_topic_subscription" "warning_email" {
  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  depends_on = [aws_sns_topic.warning_alerts]
}

# ============ CRITICAL ALARMS ============

# Alarm: Unhealthy targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "CRITICAL: One or more targets are unhealthy"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_name
    TargetGroup  = var.target_group_name
  }

  tags = {
    Environment = var.environment
  }
}

# Alarm: High ALB response time
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${var.project_name}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "CRITICAL: Response time is too high (>1 second)"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name
  }

  tags = {
    Environment = var.environment
  }
}

# ============ WARNING ALARMS ============

# Alarm: High EC2 CPU
resource "aws_cloudwatch_metric_alarm" "high_ec2_cpu" {
  alarm_name          = "${var.project_name}-high-ec2-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "WARNING: EC2 CPU > 75% - may need scaling"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Environment = var.environment
  }
}

# Alarm: High RDS CPU
resource "aws_cloudwatch_metric_alarm" "high_rds_cpu" {
  alarm_name          = "${var.project_name}-high-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "WARNING: RDS CPU > 80% - performance may degrade"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Environment = var.environment
  }
}

# Alarm: High database connections
resource "aws_cloudwatch_metric_alarm" "high_db_connections" {
  alarm_name          = "${var.project_name}-high-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "WARNING: Database connections > 80% of max"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Environment = var.environment
  }
}

# Alarm: RDS low memory
resource "aws_cloudwatch_metric_alarm" "low_rds_memory" {
  alarm_name          = "${var.project_name}-low-rds-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 268435456
  alarm_description   = "WARNING: RDS free memory < 256 MB"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Environment = var.environment
  }
}

output "critical_alert_topic_arn" {
  value = aws_sns_topic.critical_alerts.arn
}

output "warning_alert_topic_arn" {
  value = aws_sns_topic.warning_alerts.arn
}