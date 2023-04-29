terraform {
  required_version = ">= 1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
  }
}

# Grab the list of availability zones
data "aws_availability_zones" "available" {}

# Create a VPC to launch our instances into
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.19.0"
  name                 = "${var.eks_cluster_name}-vpc"
  cidr                 = var.vpc_cidr_block
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  vpc_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }
}
