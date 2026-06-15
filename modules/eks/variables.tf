# =========================================================
# EKS Module Variables
# =========================================================

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the vpc module."
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private app subnet IDs — nodes run here."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs — required for EKS control plane."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group ID — allows ALB to reach nodes."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.micro"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "db_password" {
  description = "RDS master password — passed into pod env vars."
  type        = string
  sensitive   = true
}