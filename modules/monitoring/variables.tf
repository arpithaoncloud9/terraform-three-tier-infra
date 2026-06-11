variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
}

variable "ec2_role_name" {
  type        = string
  description = "EC2 IAM role name"
}

variable "alert_email" {
  type        = string
  description = "Email address for receiving alerts"
}

variable "alb_name" {
  type        = string
  description = "Application Load Balancer name"
}

variable "target_group_name" {
  type        = string
  description = "Target group name"
}

variable "asg_name" {
  type        = string
  description = "Auto Scaling Group name"
}

variable "rds_instance_id" {
  type        = string
  description = "RDS instance identifier"
}