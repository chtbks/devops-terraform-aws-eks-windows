output "vpc_id" {
  value       = module.test.vpc_id
  description = "VPC ID"
}

output "private_subnet_ids" {
  value       = module.test.private_subnet_ids
  description = "VPC private subnet IDs"
}

output "public_subnet_ids" {
  value       = module.test.public_subnet_ids
  description = "VPC public subnet IDs"
}

output "eks_cluster_name" {
  value       = module.test.eks_cluster_name
  description = "EKS cluster ID"
}

output "eks_cluster_endpoint" {
  value       = module.test.eks_cluster_endpoint
  description = "EKS cluster endpoint"
}
output "eks_cluster_certificate_authority_data" {
  value       = module.test.eks_cluster_certificate_authority_data
  description = "EKS cluster CA"
}
output "kubeconfig" {
  value       = module.test.kubeconfig
  description = "kubeconfig for the AWS EKS cluster"
}
