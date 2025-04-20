data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group]
  subnet_id              = var.private_subnets[0]

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
