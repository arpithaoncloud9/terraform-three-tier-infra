variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the app tier will live."
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private app subnet IDs across AZs for the ASG."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB - app tier accepts traffic only from this."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group to register instances with."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the app tier."
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG."
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG."
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
}
