# Nova Iris EKS Infrastructure

This repository contains the Terraform code to manage the AWS EKS infrastructure for Nova Iris.

## Directory Structure

The codebase is organized in a modular structure to improve maintainability and scalability:

```
eks-infrastructure/
├── main.tf                # Main orchestration file
├── variables.tf           # Input variables
├── outputs.tf             # Output variables
├── providers.tf           # Provider configuration
├── terraform.tfvars       # Variable values (gitignored)
│
├── infrastructure/        # Core infrastructure components
│   ├── main.tf            # VPC and EKS orchestration
│   ├── vpc.tf             # VPC configuration
│   ├── eks.tf             # EKS cluster configuration
│   ├── route53.tf         # Route53 configuration
│   ├── variables.tf       # Infrastructure variables
│   ├── outputs.tf         # Infrastructure outputs
│   └── versions.tf        # Terraform and provider versions
│
├── addons/                # Cluster add-ons
│   ├── main.tf            # Add-ons orchestration
│   ├── load_balancer_controller.tf  # AWS ALB Controller
│   ├── cert_manager.tf              # Certificate Manager
│   ├── external_dns.tf              # External DNS
│   ├── argocd.tf                    # ArgoCD
│   ├── variables.tf                 # Add-ons variables
│   └── versions.tf                  # Terraform and provider versions
│
├── applications/          # Application deployments
│   ├── main.tf            # Applications orchestration
│   ├── variables.tf       # Applications variables
│   ├── versions.tf        # Terraform and provider versions
│   └── values/            # Helm values files
│       └── argocd_values.yaml       # ArgoCD values
│
└── modules/               # Reusable modules
    ├── eks/               # EKS module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── vpc/               # VPC module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Module Structure

### Infrastructure Module
Contains all the core infrastructure components:
- VPC with public and private subnets
- EKS cluster
- Route53 DNS zone configuration

### Addons Module
Contains all the Kubernetes add-ons deployed via Helm:
- AWS Load Balancer Controller
- External DNS for Route53 integration
- cert-manager for certificate management
- ArgoCD for GitOps

### Applications Module
For deploying applications to the cluster:
- Organized by team or domain
- Helm values stored in a central location

## Usage

1. Configure your AWS credentials:
   ```
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_REGION="us-east-1"
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Plan your changes:
   ```
   terraform plan
   ```

4. Apply your changes:
   ```
   terraform apply --auto-approve
   ```

5. To destroy the infrastructure:
   ```
   terraform destroy --auto-approve
   ```

## Adding New Applications

When adding new applications to be deployed to the cluster:

1. Create a values file in `applications/values/`
2. Reference it in your Helm release in an appropriate location under the `applications/` directory

This structure helps keep your codebase clean as you add more applications to the cluster.

## Maintenance

When making changes to the infrastructure:
- Use the modular structure to isolate changes
- Update the README if you modify the structure
- Run `terraform fmt` before committing changes
