# EKS Infrastructure

This Terraform project provisions an Amazon EKS (Elastic Kubernetes Service) cluster along with the necessary AWS infrastructure components.

## Prerequisites

- AWS account with appropriate permissions
- Terraform installed (>= 1.0.0)
- AWS CLI configured with your credentials

## Project Structure

```
eks-infra
├── main.tf                # Main configuration for the Terraform project
├── variables.tf           # Input variables for the Terraform configuration
├── outputs.tf             # Output values returned after applying the configuration
├── providers.tf           # Provider settings for AWS
├── terraform.tfvars.example # Example variables file
├── .terraform.lock.hcl    # Lock file for provider versions
└── README.md              # Project documentation
```

## Usage

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd eks-infra
   ```

2. **Create your `terraform.tfvars` file**:
   Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values with your configuration.

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Outputs

After applying the configuration, you will receive output values that provide information about the created resources.

## Cleanup

To destroy the resources created by this Terraform configuration, run:
```bash
terraform destroy
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.
