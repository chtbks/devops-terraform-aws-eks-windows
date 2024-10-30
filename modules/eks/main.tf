terraform {
  required_version = ">= 1.4.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
  }
}
//ref https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v19.14.0/examples/eks_managed_node_group/main.tf

# put all nodes in private subnets #concat(var.private_subnet_ids, var.public_subnet_ids)
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.10.3"
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  subnet_ids      = concat(var.private_subnet_ids, var.public_subnet_ids)

  vpc_id                                 = var.vpc_id
  cluster_endpoint_public_access         = false
  aws_auth_users                         = var.eks_users
  cloudwatch_log_group_retention_in_days = 7
  kms_key_enable_default_policy          = true
  kms_key_administrators                 = var.kms_key_administrators
  kms_key_owners                         = var.kms_key_owners

  eks_managed_node_groups = {
    linux = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                 = "true",
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
      }

      instance_types = [var.eks_linux_instance_type]

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
      instance_types = [var.eks_windows_instance_type]

      min_size     = var.eks_autoscaling_group_windows_min_size
      max_size     = var.eks_autoscaling_group_windows_max_size
      desired_size = var.eks_autoscaling_group_windows_desired_capacity
      disk_size    = var.eks_windows_disk_size
      remote_access = {
        ec2_ssh_key = var.eks_windows_key_pair_name
        #        source_security_group_ids = [var.e.remote_access.id]
      }
      #      iam_role_additional_policies = {
      #        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      #        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy"
      #      }
    }
  }
  cluster_addons = {
    kube-proxy = {}
    vpc-cni = {
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          WARM_IP_TARGET           = "5"
        }
        enableWindowsIpam             = "true"
        enableWindowsPrefixDelegation = "true"
        minimumWindowsIPTarget        = 15
        warmWindowsPrefixTarget       = 1
      })
    }
    coredns = {}
  }

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

# This is managed by AWS VPC CNI add-on - see above
# https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
# https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-update.html
# resource "kubernetes_config_map_v1" "vpc_resource_controller" {
#   metadata {
#     name      = "amazon-vpc-cni"
#     namespace = "kube-system"
#   }
#   data = {
#     enable-windows-ipam = true
#   }
# }
