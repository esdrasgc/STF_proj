# STF Project - AWS Terraform Deployment

This Terraform project deploys the STF web scraping system on AWS infrastructure. The system collects, processes, and stores data in MongoDB, orchestrating the workflow with Kafka.

## Architecture

The infrastructure includes:
- A central VPC in the primary region
- Kafka broker & ZooKeeper instance for message orchestration
- MongoDB for data storage
- Multiple "coleta_processo" instances across different AWS regions
- Multiple "coleta_aba" instances across different AWS regions

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform 1.0+ installed
- SSH key for EC2 instances access

## Deployment Steps

1. **Create an SSH key for EC2 instances**

   ```bash
   cd scripts
   chmod +x generate_ssh_key.sh
   ./generate_ssh_key.sh
   cd ..
   ```

2. **Configure your deployment variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   
   Edit `terraform.tfvars` to customize your deployment:
   - Adjust the AWS regions based on your needs
   - Configure instance types and counts according to your workload
   - Set MongoDB credentials (use strong passwords!)

3. **Initialize Terraform**

   ```bash
   terraform init
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
   - Kafka and MongoDB endpoints
   - SSH commands to connect to instances

## Scaling

- To adjust the number of worker instances:
  - Modify `process_replicas_per_region` and `tabs_replicas_per_region` in your terraform.tfvars file
  - Run `terraform apply` to update

- To add or remove AWS regions:
  - Modify the `process_collection_regions` and `tabs_collection_regions` variables
  - Run `terraform apply` to update

## Security Considerations

- The MongoDB instance is configured with password authentication
- All components are deployed in private subnets where applicable
- Security groups restrict access to the necessary ports only
- Consider adding a VPN or bastion host for secure access

## Cleanup

To remove all created resources:

```bash
terraform destroy
```

Confirm by typing `yes` when prompted.
