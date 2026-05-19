output "db_endpoint" {
  description = "RDS endpoint (host:port) - use this from the app tier."
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "RDS hostname only."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the database listens on."
  value       = aws_db_instance.this.port
}

output "db_security_group_id" {
  description = "Security group ID attached to the DB."
  value       = aws_security_group.db.id
}