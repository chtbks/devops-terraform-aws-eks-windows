<!-- BEGIN_TF_DOCS -->
# EKS with Windows Terraform module

![ci workflow](https://github.com/1nval1dctf/terraform-aws-wks-windows/actions/workflows/ci.yml/badge.svg)
Terraform module to deploy EKS with Windows support


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 3.59.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.3 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.59.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region to deploy CTFd into | `string` | `"us-east-1"` | no |
| <a name="input_eks_autoscaling_group_desired_capacity"></a> [eks\_autoscaling\_group\_desired\_capacity](#input\_eks\_autoscaling\_group\_desired\_capacity) | Desired capacity for Linux nodes for the EKS. | `number` | `1` | no |
| <a name="input_eks_autoscaling_group_max_size"></a> [eks\_autoscaling\_group\_max\_size](#input\_eks\_autoscaling\_group\_max\_size) | Minimum number of Linux nodes for the EKS. | `number` | `2` | no |
| <a name="input_eks_autoscaling_group_min_size"></a> [eks\_autoscaling\_group\_min\_size](#input\_eks\_autoscaling\_group\_min\_size) | Minimum number of Linux nodes for the EKS. | `number` | `1` | no |
| <a name="input_eks_autoscaling_group_windows_desired_capacity"></a> [eks\_autoscaling\_group\_windows\_desired\_capacity](#input\_eks\_autoscaling\_group\_windows\_desired\_capacity) | Desired capacity for Windows nodes for the EKS. | `number` | `1` | no |
| <a name="input_eks_autoscaling_group_windows_max_size"></a> [eks\_autoscaling\_group\_windows\_max\_size](#input\_eks\_autoscaling\_group\_windows\_max\_size) | Maximum number of Windows nodes for the EKS. | `number` | `2` | no |
| <a name="input_eks_autoscaling_group_windows_min_size"></a> [eks\_autoscaling\_group\_windows\_min\_size](#input\_eks\_autoscaling\_group\_windows\_min\_size) | Minimum number of Windows nodes for the EKS | `number` | `1` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name for the EKS Cluster | `string` | `"eks"` | no |
| <a name="input_eks_instance_type"></a> [eks\_instance\_type](#input\_eks\_instance\_type) | Instance size for EKS worker nodes. | `string` | `"m5.large"` | no |
| <a name="input_eks_users"></a> [eks\_users](#input\_eks\_users) | Additional AWS users to add to the EKS aws-auth configmap. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | EKS cluster ID |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | kubectl config file contents for this EKS cluster. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2) |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnets that contain frontend infrastructure (ALB) |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | Id for the VPC created for CTFd |

## Examples
### Simple

```hcl
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

```

## Building / Contributing

### Install prerequisites

#### Golang

```bash
wget https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
rm go1.17.1.linux-amd64.tar.gz
```

#### Terraform

```bash
LATEST_URL=$(curl https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1)
curl ${LATEST_URL} > /tmp/terraform.zip
(cd /tmp && unzip /tmp/terraform.zip && chmod +x /tmp/terraform && sudo mv /tmp/terraform /usr/local/bin/)
```

#### Pre-commit and tools

Follow: https://github.com/antonbabenko/pre-commit-terraform#how-to-install

### Run tests

Default tests will run through various validation steps .
```bash
make
```

To test actual deployment to AWS.
```bash
make test_aws
```

> :warning: **Warning**: This will spin up EKS and other services in AWS which will cost you some money.
<!-- END_TF_DOCS -->