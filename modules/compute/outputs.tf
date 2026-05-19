output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group."
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template used by the ASG."
  value       = aws_launch_template.app.id
}

output "app_security_group_id" {
  description = "Security group ID of the app tier."
  value       = aws_security_group.app.id
}