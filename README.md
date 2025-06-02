# STF Process Scraper Project

This project implements a distributed web scraping system to collect and process information from the STF (Supremo Tribunal Federal - Brazilian Supreme Court) portal. It uses Kafka for message queuing, MongoDB for data storage, and deploys worker instances across multiple AWS regions using Terraform.

## Architecture Overview

*   **Data Ingestion (`coleta_ids`):** A FastAPI application (run locally via Docker Compose or potentially deployed) allows users to submit ranges of process IDs. These IDs are sent to a Kafka topic.
*   **Kafka:** Acts as a message broker for distributing process IDs and task assignments.
    *   `ids_processo` topic: Receives initial process IDs to be scraped.
    *   `abas` topic: Receives tasks to scrape specific tabs (details, parties, etc.) for a given process ID.
*   **MongoDB:** Stores the scraped data.
*   **`coleta_processo` Workers:** EC2 instances deployed in various AWS regions. They consume IDs from the `ids_processo` topic, scrape the main page of each process, store initial data in MongoDB, and produce messages to the `abas` topic for further detailed scraping.
*   **`coleta_aba` Workers:** EC2 instances deployed in various AWS regions. They consume tasks from the `abas` topic, scrape the detailed information from specific tabs of a process, and update the corresponding record in MongoDB.
*   **Infrastructure:** Managed by Terraform, including VPC, subnets, security groups, EC2 instances, IAM roles, and Elastic IPs.

## Prerequisites

*   **Docker & Docker Compose:** For local development and running the `coleta_ids` service.
*   **Python 3.10+:** For running helper scripts.
*   **AWS CLI:** Configured with appropriate credentials and default region.
*   **Terraform 1.0+:** For deploying AWS infrastructure.
*   **`kafkacat` (optional):** Useful for interacting with Kafka from the command line.
*   **`ssh-keygen`:** For generating SSH key pairs if needed.

## Local Development Setup (Docker Compose)

The `docker-compose.yaml` file sets up a local environment with:
*   Zookeeper
*   Kafka Broker
*   MongoDB & Mongo Express
*   `create_topics` service: Automatically creates necessary Kafka topics.
*   `coleta_ids` service: FastAPI frontend to send ID ranges to Kafka.
*   `coleta_processo` service: Local worker for scraping main process pages.
*   `coleta_aba` service: Local worker for scraping process tabs.

**Steps:**

1.  **Environment Variables:**
    Copy `.env.example` to `.env` and customize if necessary (though defaults should work for local Docker setup).
    ```bash
    cp .env.example .env
    ```

2.  **Build and Run Docker Compose:**
    ```bash
    docker-compose up --build -d
    ```
    *   The `-d` flag runs services in detached mode.
    *   Services like `coleta_processo` and `coleta_aba` are set to `restart: always`.

3.  **Access Services:**
    *   **`coleta_ids` (FastAPI):** `http://localhost:80` (mapped from container port 8000)
    *   **Mongo Express:** `http://localhost:8081`
    *   **Kafka Broker:** `localhost:9092` (from outside Docker network) or `kafka_broker:29092` (from within Docker network).
    *   **MongoDB:** `localhost:27017`

4.  **Stopping Services:**
    ```bash
    docker-compose down
    ```

## AWS Deployment (Terraform)

The Terraform configuration in the `./terraform` directory deploys the Kafka, MongoDB, and worker instances (`coleta_processo`, `coleta_aba`) to AWS.

**Steps:**

1.  **Navigate to Terraform Directory:**
    ```bash
    cd terraform
    ```

2.  **Prepare SSH Key:**
    *   The Terraform setup (`key_pairs.tf`) will manage the creation/import of an SSH key pair named `stf-proj-key` (or as defined in `var.ssh_key_name`) in all relevant AWS regions.
    *   Ensure you have the private key (`stf-proj-key.pem`) and public key (`stf-proj-key.pub`) in the `terraform/scripts/` directory.
    *   If they don't exist, the `scripts/generate_ssh_key.sh` script can help create them locally:
        ```bash
        cd scripts
        chmod +x generate_ssh_key.sh
        ./generate_ssh_key.sh
        cd ..
        ```
        *(Note: The script's AWS import functionality is now handled by Terraform, but it's still useful for local key generation.)*

3.  **Configure Deployment Variables:**
    Copy `terraform.tfvars.example` to `terraform.tfvars` and customize:
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```
    Key variables to review:
    *   `aws_main_region`: Primary region for Kafka and MongoDB.
    *   `active_process_regions`, `active_tabs_regions`: Lists of AWS regions to deploy worker instances. Ensure these regions have provider aliases in `providers.tf` and static module blocks in `main.tf`.
    *   `mongodb_password`: **Set a strong, unique password.**
    *   `ssh_key_name`: Should match the name of your key files (e.g., "stf-proj-key").
    *   Instance types and replica counts.

4.  **Initialize Terraform:**
    ```bash
    terraform init -upgrade
    ```

5.  **Import Existing Key Pairs (First Time with Terraform Key Management):**
    If the SSH key pairs already exist in your AWS regions (e.g., from previous manual creation or script runs), you need to import them into Terraform's state. **Run these commands from the `terraform` directory.**
    ```bash
    # Import the key pair in the default (main) region
    terraform import aws_key_pair.main_key_pair stf-proj-key

    # Import for other configured regions (only if the region is NOT the main_region)
    # Example for us-west-2, if main_region is us-east-1:
    # terraform import -provider=aws.us_west_2 aws_key_pair.us_west_2 stf-proj-key
    # ... repeat for other non-main regions defined in key_pairs.tf and active in terraform.tfvars
    ```
    *Refer to `key_pairs.tf` for the resource names and `providers.tf` for provider aliases.*
    *The `count` logic in `key_pairs.tf` now handles avoiding duplicate creation if a region is the main region.*

6.  **Preview Deployment Plan:**
    ```bash
    terraform plan
    ```
    Review the plan carefully.

7.  **Apply Configuration:**
    ```bash
    terraform apply
    ```
    Confirm by typing `yes` when prompted.

## How to Use (After AWS Deployment)

1.  **Get Service Endpoints:**
    After `terraform apply` completes, it will output the public IP for MongoDB and the private IP for Kafka.
    ```bash
    terraform output
    ```
    *   `mongodb_endpoint`: Public IP of the MongoDB instance.
    *   `kafka_endpoint`: Private IP of the Kafka instance (accessible from within the VPC or via SSH tunnel/VPN).

2.  **Send IDs to Kafka:**
    You have several options:
    *   **Run `coleta_ids` locally (Docker):**
        *   Update your local `.env` file with the **private IP** of the deployed Kafka broker:
            ```
            KAFKA_BROKER_HOST=<private_kafka_ip_from_terraform_output>
            KAFKA_BROKER_PORT=9092
            ```
        *   Run the `coleta_ids` service: `docker-compose up coleta_ids`
        *   Access `http://localhost:80` to submit ID ranges.
    *   **Use `send_ids_to_kafka.py` script:**
        This script connects directly to Kafka. You'll need an SSH tunnel or VPN to reach the private Kafka IP.
        ```bash
        # Example: SSH Tunnel (run in a separate terminal)
        # ssh -i scripts/stf-proj-key.pem -L 9092:<private_kafka_ip_from_terraform_output>:9092 ec2-user@<kafka_instance_public_ip_if_any_or_bastion_ip>

        python send_ids_to_kafka.py localhost:9092 <start_id> <end_id>
        ```
    *   **Use `kafkacat`:**
        Requires an SSH tunnel or VPN similar to the Python script.
        ```bash
        # KAFKA_ENDPOINT should be localhost if using a tunnel, or the direct private IP if accessible
        for i in {2000000..2000010}; do
          echo "$i" | kafkacat -P -b ${KAFKA_ENDPOINT}:9092 -t ids_processo -k "$i"
        done
        ```

3.  **Monitor Workers:**
    *   You can SSH into the EC2 instances for `coleta_processo` and `coleta_aba` to view their logs (e.g., in `/var/log/cloud-init-output.log` or wherever your startup script directs them).
    *   Check MongoDB for incoming data.

## Scaling and Region Management (AWS)

*   **Adjusting Replicas:**
    *   Modify `process_replicas_per_region` and `tabs_replicas_per_region` in `terraform/terraform.tfvars`.
    *   Run `terraform apply` from the `terraform` directory.
*   **Activating/Deactivating Regions for Workers:**
    *   Add or remove region names from `active_process_regions` and `active_tabs_regions` in `terraform/terraform.tfvars`.
    *   Ensure corresponding static module blocks (e.g., `module "coleta_processo_us_west_2"`) exist in `terraform/main.tf` and provider aliases exist in `terraform/providers.tf`.
    *   Run `terraform apply`.
*   **Adding New Potential Regions for Workers:**
    *   Define a new provider alias in `terraform/providers.tf`.
    *   Add corresponding static module blocks in `terraform/main.tf`.
    *   Add the new region to `terraform/key_pairs.tf`.
    *   You can then add the region to the `active_..._regions` lists in `terraform.tfvars`.
    *   Run `terraform apply`.

## Security Considerations

*   **MongoDB Public Access:** The current Terraform configuration makes MongoDB accessible via a public Elastic IP. **This is a significant security risk.**
    *   **USE A VERY STRONG, UNIQUE PASSWORD** for `mongodb_password` in `terraform.tfvars`.
    *   The security group (`mongodb_sg` in `modules/network/security_groups.tf`) allows traffic from `0.0.0.0/0` on port 27017. **Strongly consider restricting this to specific IP addresses if possible.**
    *   For production, it's highly recommended to keep MongoDB in a private subnet and access it via a bastion host, VPN, or from services within the VPC.
*   **SSH Keys:** Keep your `stf-proj-key.pem` private key secure.
*   **IAM Roles:** EC2 instances are assigned IAM roles with necessary permissions (e.g., for CloudWatch Logs). Review these permissions to ensure they follow the principle of least privilege.
*   **Kafka:** The Kafka broker is in a private subnet. Access from outside the VPC requires secure methods (SSH tunnel, VPN).

## Helper Scripts

*   `./scripts/generate_ssh_key.sh`: Helps create a local SSH key pair and its public counterpart. (AWS import part is now handled by Terraform).
*   `./send_ids_to_kafka.py`: Python script to send ID ranges directly to a Kafka topic.
*   `./limpar_topico.py`: Python script to consume and print messages from the `ids_processo` topic (can be adapted for cleanup or debugging).
*   `./create_topics.py`: Python script (used by Docker service) to create Kafka topics.

## Cleanup

*   **AWS Resources:**
    To remove all AWS resources created by Terraform:
    ```bash
    cd terraform
    terraform destroy
    ```
    Confirm by typing `yes`.
    *Note: Manually created/imported SSH key pairs in AWS might need to be deleted separately via the AWS console or CLI if not managed by `aws_key_pair` resources that are destroyed.*

*   **Local Docker Environment:**
    ```bash
    docker-compose down -v # The -v flag also removes volumes (Kafka data, MongoDB data)
    ```
