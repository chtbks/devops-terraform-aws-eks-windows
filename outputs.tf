output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Id for the VPC created for CTFd"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2)"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "List of public subnets that contain frontend infrastructure (ALB)"
}

output "eks_cluster_id" {
  value       = module.eks.eks_cluster_id
  description = "EKS cluster ID"
  depends_on = [
    module.eks,
    module.eks_extras
  ]
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.eks.kubeconfig
}
