terraform {
  required_version = "1.4.4"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
  }
}

locals {
  cluster_version = "1.25"
}

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "19.10.3"
  cluster_name                   = var.eks_cluster_name
  cluster_version                = local.cluster_version
  subnet_ids                     = var.private_subnet_ids
  vpc_id                         = var.vpc_id
  cluster_endpoint_public_access = true
  aws_auth_users                 = var.eks_users

  eks_managed_node_groups = {
    linux = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                 = "true",
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
      }

      instance_types = [var.eks_instance_type]

      min_size     = var.eks_autoscaling_group_linux_min_size
      max_size     = var.eks_autoscaling_group_linux_max_size
      desired_size = var.eks_autoscaling_group_linux_desired_capacity
    }
    windows = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false
      ami_type                   = var.windows_ami_type
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                 = "true",
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
      }
      instance_types = [var.eks_instance_type]

      min_size     = var.eks_autoscaling_group_windows_min_size
      max_size     = var.eks_autoscaling_group_windows_max_size
      desired_size = var.eks_autoscaling_group_windows_desired_capacity
    }
  }
  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns    = {}
  }
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

resource "kubernetes_config_map_v1" "vpc_resource_controller" {
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }
  data = {
    enable-windows-ipam = true
  }
}
