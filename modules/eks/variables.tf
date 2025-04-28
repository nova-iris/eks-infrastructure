variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.27"
}

variable "vpc_id" {
  description = "VPC where the cluster and workers will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where workers can be created"
  type        = list(string)
}

variable "node_group" {
  description = "Configuration for the EKS managed node group"
  type = object({
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = list(string)
    capacity_type  = string
    node_labels    = map(string)
  })
  default = {
    min_size       = 1
    max_size       = 3
    desired_size   = 2
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    node_labels    = {}
  }
}

# Keeping these for backwards compatibility, they'll be removed in future versions
variable "min_size" {
  description = "Minimum number of nodes in the node group (deprecated, use node_group.min_size)"
  type        = number
  default     = null
}

variable "max_size" {
  description = "Maximum number of nodes in the node group (deprecated, use node_group.max_size)"
  type        = number
  default     = null
}

variable "desired_size" {
  description = "Desired number of nodes in the node group (deprecated, use node_group.desired_size)"
  type        = number
  default     = null
}

variable "instance_types" {
  description = "List of instance types for the node group (deprecated, use node_group.instance_types)"
  type        = list(string)
  default     = null
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group (deprecated, use node_group.capacity_type)"
  type        = string
  default     = null
}

variable "node_labels" {
  description = "Labels to apply to the node group (deprecated, use node_group.node_labels)"
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type        = any
  default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
}
