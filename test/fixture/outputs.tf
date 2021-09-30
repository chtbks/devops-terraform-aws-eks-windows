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

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.test.kubeconfig
}
