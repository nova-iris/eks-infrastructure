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
│   ├── rancher.tf                   # Rancher
│   ├── variables.tf                 # Add-ons variables
│   ├── versions.tf                  # Terraform and provider versions
│   └── values/                      # Helm values files
│       └── argocd.yaml              # ArgoCD values
│
├── applications/          # Application deployments
│   ├── main.tf            # Applications orchestration
│   ├── variables.tf       # Applications variables
│   ├── versions.tf        # Terraform and provider versions
│   └── values/            # Helm values files
│
├── backup/                # Backup of previous configurations
│   ├── argocd_values.yaml          # Backup of ArgoCD values
│   ├── argocd.tf                   # Backup of ArgoCD configuration
│   ├── cert_manager.tf             # Backup of cert-manager configuration
│   ├── external_dns.tf             # Backup of External DNS configuration
│   ├── helm.tf                     # Backup of Helm configuration
│   ├── load_balancer_controller.tf # Backup of AWS ALB Controller configuration
│   ├── ebs_csi_driver.tf           # Backup of AWS EBS CSI Driver configuration
│   └── efs_csi_driver.tf           # Backup of AWS EFS CSI Driver configuration
│
└── modules/               # Reusable modules
    ├── eks/               # EKS module
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md      # EKS module documentation
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
- AWS Load Balancer Controller (Version: 1.12.0)
- External DNS for Route53 integration (Version: 6.20.0)
- cert-manager for certificate management (Version: v1.17.1)
- ArgoCD for GitOps (Version: 7.8.15)

### Applications Module
For deploying applications to the cluster:
- Organized by team or domain
- Helm values stored in a central location

### Backup Directory
Contains backup copies of previous configurations:
- Used for reference and rollback if needed
- Includes previous versions of Helm charts and configurations

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
   
   To enable storage drivers:
   ```
   # Enable EBS CSI Driver
   terraform apply -var="enable_ebs_csi_driver=true" --auto-approve
   
   # Enable EFS CSI Driver
   terraform apply -var="enable_efs_csi_driver=true" --auto-approve
   
   # Enable both storage drivers
   terraform apply -var="enable_ebs_csi_driver=true" -var="enable_efs_csi_driver=true" --auto-approve
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

## Component Versions

The following component versions are currently deployed:

| Component | Version |
|-----------|---------|
| AWS Load Balancer Controller | 1.12.0 |
| External DNS | 6.20.0 |
| cert-manager | v1.17.1 |
| ArgoCD | 7.8.15 |

## Maintenance

When making changes to the infrastructure:
- Use the modular structure to isolate changes
- Update the README if you modify the structure
- Run `terraform fmt` before committing changes
- Ensure version updates are reflected in the component versions section
