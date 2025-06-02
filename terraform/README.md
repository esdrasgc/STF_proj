# STF Project - AWS Terraform Deployment

This Terraform project deploys the STF web scraping system on AWS infrastructure. The system collects, processes, and stores data in MongoDB, orchestrating the workflow with Kafka.

## Architecture

The infrastructure includes:
- A central VPC in the primary region (`var.aws_main_region`)
- Kafka broker & ZooKeeper instance in the primary region
- MongoDB instance in the primary region
- Multiple "coleta_processo" instances across selected AWS regions (`var.active_process_regions`)
- Multiple "coleta_aba" instances across selected AWS regions (`var.active_tabs_regions`)

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform 1.0+ installed
- An existing SSH key pair registered in AWS EC2 for the regions you intend to deploy to, or use the provided script to generate one.

## Deployment Steps

1. **Ensure SSH key exists or create one**

   If you don't have an SSH key named `stf-proj-key` (or the name you intend to use in `terraform.tfvars`) registered in the relevant AWS regions, you can use the provided script:
   ```bash
   cd scripts
   chmod +x generate_ssh_key.sh
   ./generate_ssh_key.sh # This creates the key in the default AWS CLI region
   cd ..
   ```
   *Note: The script creates the key pair in AWS. Ensure the corresponding private key (`.pem` file) is available locally.*

2. **Configure your deployment variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars` to customize your deployment:
   - Set `aws_main_region` for Kafka/MongoDB.
   - Define the lists `active_process_regions` and `active_tabs_regions` to specify which regions should have worker instances deployed. Ensure these regions have corresponding provider aliases defined in `providers.tf` and static module blocks in `main.tf`.
   - Configure instance types (`kafka_instance_type`, `mongodb_instance_type`, etc.) and replica counts (`process_replicas_per_region`, `tabs_replicas_per_region`). Ensure instance types match the desired architecture (e.g., `t4g.*` for ARM, `t3.*` for x86).
   - Set MongoDB credentials (`mongodb_password` - use a strong password!).
   - Set `ssh_key_name` to match your existing key pair name in AWS.

3. **Initialize Terraform**

   ```bash
   terraform init -upgrade
   ```

4. **Preview the deployment plan**

   ```bash
   terraform plan
   ```

5. **Apply the configuration**

   ```bash
   terraform apply
   ```

   Confirm by typing `yes` when prompted.

6. **Access your infrastructure**

   After deployment, Terraform will output:
   - Kafka and MongoDB private IP endpoints (accessible within the VPC)
   - Example SSH commands (may require a bastion host or VPC peering for external access)

## Scaling and Region Management

- **Adjusting Replicas:**
  - Modify `process_replicas_per_region` and `tabs_replicas_per_region` in `terraform.tfvars`.
  - Run `terraform apply`.

- **Activating/Deactivating Regions:**
  - Add or remove region names (e.g., "us-west-2", "eu-central-1") from the `active_process_regions` and `active_tabs_regions` lists in `terraform.tfvars`.
  - Ensure that corresponding static module blocks (e.g., `module "coleta_processo_us_west_2"`) exist in `main.tf` and provider aliases exist in `providers.tf` for any region you wish to activate.
  - Run `terraform apply`.

- **Adding New Potential Regions:**
  - Define a new provider alias in `providers.tf` (e.g., `provider "aws" { alias = "ap_northeast_1" region = "ap-northeast-1" }`).
  - Add corresponding static module blocks in `main.tf` for `coleta_processo` and `coleta_aba` (e.g., `module "coleta_processo_ap_northeast_1" { ... providers = { aws = aws.ap_northeast_1 } ... }`).
  - You can then add "ap-northeast-1" to the `active_...` lists in `terraform.tfvars` when desired.
  - Run `terraform apply`.

## Security Considerations

- The MongoDB instance is configured with password authentication.
- Components are deployed in private subnets where applicable. Access from outside the VPC requires additional setup (e.g., Bastion Host, VPN, VPC Peering).
- Security groups restrict access to necessary ports. Review and tighten rules as needed.
- Ensure the SSH private key (`.pem` file) is kept secure and has appropriate file permissions (e.g., `chmod 400 key.pem`).

## Cleanup

To remove all created resources:

```bash
terraform destroy
```

Confirm by typing `yes` when prompted.
