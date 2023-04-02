output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Id for the VPC created for teh EKS"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "List of private subnets"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "List of public subnets"
}
output "intra_subnet_ids" {
  value       = module.vpc.intra_subnets
  description = "List of intra subnets"
}
