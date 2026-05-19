variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB and target group will live."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs across AZs for the ALB."
  type        = list(string)
}