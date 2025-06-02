data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Deploy N replicas of coleta_processo in a specific region
resource "aws_instance" "coleta_processo" {
  count         = var.replicas_per_region
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, count.index % length(var.subnet_ids))
  vpc_security_group_ids = [var.app_security_group_id]
  key_name      = var.ssh_key_name
  iam_instance_profile = var.iam_instance_profile_name

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "Starting user data script..."

              # Install dependencies
              yum update -y
              yum install -y python3 python3-pip git

              # Create app directory
              APP_DIR="/opt/stf_scraper"
              mkdir -p $APP_DIR
              cd $APP_DIR

              # Clone the application code
              echo "Cloning repository from ${var.git_repo_url}..."
              git clone "${var.git_repo_url}" .
              
              # Install Python dependencies
              if [ -f "requirements.txt" ]; then
                echo "Installing Python dependencies from requirements.txt..."
                pip3 install -r requirements.txt
              else
                echo "requirements.txt not found in repository root."
              fi

              # Create environment file for the service
              echo "Creating .env file..."
              cat <<ENV_EOF > $APP_DIR/.env
KAFKA_BROKER_HOST=${var.kafka_broker_host}
KAFKA_BROKER_PORT=9092
MONGO_INITDB_ROOT_USERNAME=${var.mongodb_username}
MONGO_INITDB_ROOT_PASSWORD=${var.mongodb_password}
MONGO_HOST=${var.mongodb_host}
MONGO_PORT=27017
MONGO_DB=${var.mongodb_db}
ENV_EOF
              chown ec2-user:ec2-user $APP_DIR/.env # Ensure ec2-user can read it

              # Create systemd service file
              echo "Creating systemd service file for coleta_processo..."
              cat <<SERVICE_EOF > /etc/systemd/system/coleta_processo.service
[Unit]
Description=STF Coleta Processo Service
Wants=network-online.target
After=network-online.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=/usr/bin/python3 $APP_DIR/coleta_processo.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/coleta_processo.log
StandardError=append:/var/log/coleta_processo.error.log

[Install]
WantedBy=multi-user.target
SERVICE_EOF

              # Enable and start the service
              echo "Enabling and starting coleta_processo service..."
              systemctl daemon-reload
              systemctl enable coleta_processo.service
              systemctl start coleta_processo.service
              echo "User data script finished."
              EOF

  tags = {
    Name        = "${var.project}-${var.environment}-coleta-processo-${var.region}-${count.index}"
    Environment = var.environment
    Project     = var.project
    Region      = var.region
  }
}
