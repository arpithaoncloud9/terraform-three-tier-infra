output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB. Visit this in a browser to test."
  value       = module.alb.alb_dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = module.compute.asg_name
}

output "db_endpoint" {
  description = "RDS endpoint (host:port) for the app to connect to."
  value       = module.database.db_endpoint
  sensitive   = true
}

output "cloudwatch_dashboard_url" {
  value       = module.monitoring.dashboard_url
  description = "URL to CloudWatch Dashboard"
}

output "critical_alert_topic" {
  value       = module.monitoring.critical_alert_topic_arn
  description = "SNS Topic for critical alerts"
}

output "warning_alert_topic" {
  value       = module.monitoring.warning_alert_topic_arn
  description = "SNS Topic for warning alerts"
}

output "log_group_name" {
  value       = module.monitoring.log_group_name
  description = "CloudWatch Log Group name"
}