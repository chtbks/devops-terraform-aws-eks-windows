variable "eks_cluster_id" {
  type        = string
  description = "EKS Cluster id"
}

variable "eks_worker_iam_role_name" {
  description = "default IAM role name for EKS worker groups"
  default     = null
  type        = string
}
