terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.59.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3"
    }
  }
}

module "vpc" {
  source           = "./modules/vpc"
  eks_cluster_name = var.eks_cluster_name
}

module "eks" {
  eks_cluster_name                               = var.eks_cluster_name
  source                                         = "./modules/eks"
  vpc_id                                         = module.vpc.vpc_id
  private_subnet_ids                             = module.vpc.private_subnet_ids
  public_subnet_ids                              = module.vpc.public_subnet_ids
  eks_users                                      = var.eks_users
  eks_autoscaling_group_min_size                 = var.eks_autoscaling_group_min_size
  eks_autoscaling_group_desired_capacity         = var.eks_autoscaling_group_desired_capacity
  eks_autoscaling_group_max_size                 = var.eks_autoscaling_group_max_size
  eks_instance_type                              = var.eks_instance_type
  eks_autoscaling_group_windows_min_size         = var.eks_autoscaling_group_windows_min_size
  eks_autoscaling_group_windows_desired_capacity = var.eks_autoscaling_group_windows_desired_capacity
  eks_autoscaling_group_windows_max_size         = var.eks_autoscaling_group_windows_max_size
}

module "eks_extras" {
  source                   = "./modules/eks-extras"
  eks_cluster_id           = module.eks.eks_cluster_id
  eks_worker_iam_role_name = module.eks.eks_worker_iam_role_name
  depends_on = [
    module.eks,
    module.vpc
  ]
}
