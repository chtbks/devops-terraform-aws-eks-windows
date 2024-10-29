terraform {
  required_version = ">= 1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
  }
}

module "vpc" {
  source                   = "./modules/vpc"
  eks_cluster_name         = var.eks_cluster_name
  vpc_cidr_block           = var.vpc_cidr_block
  vpc_cidr_private_subnets = var.vpc_cidr_private_subnets
  vpc_cidr_public_subnets  = var.vpc_cidr_public_subnets
}

module "eks" {
  eks_cluster_name                               = var.eks_cluster_name
  source                                         = "./modules/eks"
  vpc_id                                         = module.vpc.vpc_id
  private_subnet_ids                             = module.vpc.private_subnet_ids
  public_subnet_ids                              = module.vpc.public_subnet_ids
  eks_users                                      = var.eks_users
  eks_cluster_version                            = var.eks_cluster_version
  eks_autoscaling_group_linux_min_size           = var.eks_autoscaling_group_linux_min_size
  eks_autoscaling_group_linux_desired_capacity   = var.eks_autoscaling_group_linux_desired_capacity
  eks_autoscaling_group_linux_max_size           = var.eks_autoscaling_group_linux_max_size
  eks_windows_instance_type                      = var.eks_windows_instance_type
  eks_linux_instance_type                        = var.eks_linux_instance_type
  eks_autoscaling_group_windows_min_size         = var.eks_autoscaling_group_windows_min_size
  eks_autoscaling_group_windows_desired_capacity = var.eks_autoscaling_group_windows_desired_capacity
  eks_autoscaling_group_windows_max_size         = var.eks_autoscaling_group_windows_max_size
  windows_ami_type                               = var.windows_ami_type
  eks_windows_key_pair_name                      = var.eks_windows_key_pair_name
  eks_windows_disk_size                          = var.eks_windows_disk_size
  kms_key_owners                                 = var.kms_key_owners
  kms_key_administrators                         = var.kms_key_administrators
}
module "eks_extras" {
  source                        = "./modules/eks-extras"
  eks_cluster_name              = module.eks.cluster_name
  vpc_id                        = module.vpc.vpc_id
  linux_node_group_iam_role     = module.eks.linux_node_group_iam_role
  windows_node_group_iam_role   = module.eks.windows_node_group_iam_role
  external_dns_support          = var.external_dns_support
  enable_metrics_server         = var.enable_metrics_server
  enable_cluster_autoscaler     = var.enable_cluster_autoscaler
  enable_cloudwatch_exported    = var.enable_cloudwatch_exported
  enable_loadbalancer_controler = var.enable_loadbalancer_controler
  eks_cluster_oicd_provider_arn = module.eks.cluster_oicd_provider_arn
  depends_on = [
    module.eks,
    module.vpc
  ]
}
