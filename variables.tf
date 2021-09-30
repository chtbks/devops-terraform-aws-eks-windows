variable "eks_cluster_name" {
  type        = string
  default     = "eks"
  description = "Name for the EKS Cluster"
}

variable "aws_region" {
  type        = string
  description = "Region to deploy CTFd into"
  default     = "us-east-1"
}

variable "eks_users" {
  description = "Additional AWS users to add to the EKS aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

# EKS autoscaling
variable "eks_autoscaling_group_min_size" {
  description = "Minimum number of Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_desired_capacity" {
  description = "Desired capacity for Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_max_size" {
  description = "Minimum number of Linux nodes for the EKS."
  default     = 2
  type        = number
}

variable "eks_instance_type" {
  description = "Instance size for EKS worker nodes."
  default     = "m5.large"
  type        = string
}

# EKS autoscaling for windows
variable "eks_autoscaling_group_windows_min_size" {
  description = "Minimum number of Windows nodes for the EKS"
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_windows_desired_capacity" {
  description = "Desired capacity for Windows nodes for the EKS."
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_windows_max_size" {
  description = "Maximum number of Windows nodes for the EKS."
  default     = 2
  type        = number
}
