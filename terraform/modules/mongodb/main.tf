locals {
  instance_architecture = substr(var.instance_type, 0, 3) == "t4g" ? "arm64" : (substr(var.instance_type, 0, 2) == "t3" || substr(var.instance_type, 0, 2) == "t2" ? "x86_64" : "x86_64") # Default to x86_64 if not t4g/t3/t2
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = [local.instance_architecture]
  }
}

resource "aws_eip" "mongodb_eip" {
  # instance = aws_instance.mongodb.id # Deprecated, use aws_eip_association instead
  vpc      = true # Required for VPC EIPs

  tags = {
    Name        = "${var.project}-${var.environment}-mongodb-eip"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id # Use the public subnet ID
  vpc_security_group_ids = [var.security_group] # Assuming var.security_group is passed
  key_name               = var.ssh_key_name
  associate_public_ip_address = true # Good practice for instances intended to be public, though EIP association handles it

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    
    # Create docker-compose.yml for MongoDB
    cat > /home/ec2-user/docker-compose.yml << 'EOT'
    version: '3'
    services:
      mongo:
        image: mongo:latest
        container_name: mongo
        environment:
          MONGO_INITDB_ROOT_USERNAME: root
          MONGO_INITDB_ROOT_PASSWORD: example
        ports:
          - "27017:27017"
        volumes:
          - mongo_data:/data/db

    volumes:
      mongo_data:
    EOT
    
    # Install docker-compose
    curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Run MongoDB
    cd /home/ec2-user
    /usr/local/bin/docker-compose up -d
  EOF

  tags = {
    Name        = "${var.project}-${var.environment}-mongodb"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_eip_association" "mongodb_eip_assoc" {
  instance_id   = aws_instance.mongodb.id
  allocation_id = aws_eip.mongodb_eip.id
}
