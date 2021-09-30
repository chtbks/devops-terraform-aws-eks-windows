output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = module.eks.kubeconfig
}

output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "EKS cluster ID"
}

output "eks_worker_iam_role_name" {
  description = "default IAM role name for EKS worker groups"
  value       = module.eks.worker_iam_role_name
}
