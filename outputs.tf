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