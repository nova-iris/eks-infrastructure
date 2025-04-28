module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 4, k + 4)]

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true

  # Required tags for EKS
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.vpc_name}" = "shared"
    }
  )

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.vpc_name}" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.vpc_name}" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }
}
