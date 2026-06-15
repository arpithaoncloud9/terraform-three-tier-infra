# =========================================================
# EKS Module Outputs
# =========================================================

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_name" {
  description = "EKS node group name."
  value       = aws_eks_node_group.app.node_group_name
}

output "node_role_arn" {
  description = "IAM role ARN for worker nodes."
  value       = aws_iam_role.eks_nodes.arn
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes."
  value       = aws_security_group.eks_nodes.id
}

output "node_group_asg_name" {
  description = "Auto Scaling Group name backing the EKS node group."
  value       = aws_eks_node_group.app.resources[0].autoscaling_groups[0].name
}