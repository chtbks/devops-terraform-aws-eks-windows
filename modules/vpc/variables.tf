variable "eks_cluster_name" {
  type        = string
  default     = "eks"
  description = "Name of the eks cluster. Needed for subnet tags"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The top-level CIDR block for the VPC."
  default     = "10.0.0.0/16"
}
