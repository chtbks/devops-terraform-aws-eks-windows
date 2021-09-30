terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "eks_windows" {
  source = "../../" # Actually set to "1nval1dctf/eks-windows/aws"
}
