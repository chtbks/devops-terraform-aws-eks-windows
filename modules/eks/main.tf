terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

locals {
  cluster_version = "1.21"
}

data "aws_region" "current" {}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.20.0"
  cluster_name    = var.eks_cluster_name
  cluster_version = local.cluster_version
  subnets         = concat(var.private_subnet_ids, var.public_subnet_ids)
  vpc_id          = var.vpc_id
  # needed for OpenID Connect Provider
  enable_irsa = true
  # avoid the need for aws-iam-authenticator
  kubeconfig_aws_authenticator_command      = "aws"
  kubeconfig_aws_authenticator_command_args = ["eks", "get-token", "--region", data.aws_region.current.name, "--cluster-name", var.eks_cluster_name]
  map_users                                 = var.eks_users

  workers_group_defaults = {
    root_volume_type = "gp2"
  }
  worker_groups = [
    {
      name                 = "${var.eks_cluster_name}-autoscaling-group"
      instance_type        = var.eks_instance_type
      platform             = "linux"
      asg_min_size         = var.eks_autoscaling_group_min_size
      asg_max_size         = var.eks_autoscaling_group_max_size
      asg_desired_capacity = var.eks_autoscaling_group_desired_capacity

      tags = [{
        key                 = "k8s.io/cluster-autoscaler/enabled"
        propagate_at_launch = false
        value               = "true"
        }, {
        key                 = "k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
        propagate_at_launch = false
        value               = "true"
      }]
    }
  ]
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]
}

module "alb_ingress_controller" {
  source  = "iplabs/alb-ingress-controller/kubernetes"
  version = "3.4.0"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = data.aws_region.current.name
  k8s_cluster_name = module.eks.cluster_id
}
