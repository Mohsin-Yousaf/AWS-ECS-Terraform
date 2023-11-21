############################

# Creating VPC

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.aws_resource_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"] 
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2), cidrsubnet(var.vpc_cidr, 8, 3)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 101), cidrsubnet(var.vpc_cidr, 8, 102), cidrsubnet(var.vpc_cidr, 8, 103)]


  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}
