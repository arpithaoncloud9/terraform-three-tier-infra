variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the DB will live."
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private DB subnet IDs across AZs."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the app tier - DB accepts traffic only from this."
  type        = string
}

variable "db_engine" {
  description = "Database engine (mysql or postgres)."
  type        = string
}

variable "db_engine_version" {
  description = "Database engine version."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "db_username" {
  description = "Master DB username."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master DB password."
  type        = string
  sensitive   = true
}