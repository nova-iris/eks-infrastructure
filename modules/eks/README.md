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

  # Object-based node group configuration
  node_group = {
    min_size       = 1
    max_size       = 3
    desired_size   = 2
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    node_labels    = {
      "cluster-autoscaler-enabled" = "true"
    }
  }

  # EKS cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          WARM_IP_TARGET = "5"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

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
| node_group | Object-based configuration for the node group | object({ min_size = number, max_size = number, desired_size = number, instance_types = list(string), capacity_type = string, node_labels = map(string) }) | { min_size = 1, max_size = 3, desired_size = 2, instance_types = ["t3.medium"], capacity_type = "ON_DEMAND", node_labels = {} } | no |
| cluster_addons | Configuration for EKS cluster addons | map(object({ most_recent = bool, configuration_values = string })) | {} | no |
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