# EKS Module

This module creates an Amazon EKS cluster using the terraform-aws-modules/eks/aws module.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.27"
  vpc_id          = "vpc-xxxxxx"
  subnet_ids      = ["subnet-xxxxx", "subnet-yyyy"]

  min_size     = 1
  max_size     = 3
  desired_size = 2

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | string | n/a | yes |
| cluster_version | Kubernetes version to use for the EKS cluster | string | "1.27" | no |
| vpc_id | VPC where the cluster and workers will be deployed | string | n/a | yes |
| subnet_ids | List of subnet IDs where workers can be created | list(string) | n/a | yes |
| min_size | Minimum number of nodes in the node group | number | 1 | no |
| max_size | Maximum number of nodes in the node group | number | 3 | no |
| desired_size | Desired number of nodes in the node group | number | 2 | no |
| instance_types | List of instance types for the node group | list(string) | ["t3.medium"] | no |
| capacity_type | Type of capacity associated with the EKS Node Group | string | "ON_DEMAND" | no |
| node_labels | Labels to apply to the node group | map(string) | {} | no |
| tags | A map of tags to add to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The name/id of the EKS cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_iam_role_arn | IAM role ARN of the EKS cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster |
| node_security_group_id | Security group ID attached to the EKS nodes |