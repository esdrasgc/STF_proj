locals {
  instance_architecture = substr(var.instance_type, 0, 3) == "t4g" ? "arm64" : "x86_64"
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

resource "aws_instance" "kafka_zookeeper" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group]
  subnet_id              = var.private_subnets[0]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    
    # Create docker-compose.yml for Kafka and Zookeeper
    cat > /home/ec2-user/docker-compose.yml << 'EOT'
    version: '3'
    services:
      zookeeper:
        image: confluentinc/cp-zookeeper:latest
        container_name: zookeeper
        environment:
          ZOOKEEPER_CLIENT_PORT: 2181
          ZOOKEEPER_TICK_TIME: 2000
        volumes:
          - zookeeper_data:/var/lib/zookeeper/data
          - zookeeper_log:/var/lib/zookeeper/log

      kafka_broker:
        image: confluentinc/cp-kafka:latest
        container_name: kafka_broker
        ports:
          - "9092:9092"
        environment:
          KAFKA_BROKER_ID: 1
          KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
          KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INSIDE:PLAINTEXT,OUTSIDE:PLAINTEXT
          KAFKA_ADVERTISED_LISTENERS: INSIDE://kafka_broker:29092,OUTSIDE://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):9092
          KAFKA_LISTENERS: INSIDE://0.0.0.0:29092,OUTSIDE://0.0.0.0:9092
          KAFKA_INTER_BROKER_LISTENER_NAME: INSIDE
          KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
          KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
        volumes:
          - kafka_data:/var/lib/kafka/data
        depends_on:
          - zookeeper

      create_topics:
        image: confluentinc/cp-kafka:latest
        depends_on:
          - kafka_broker
        entrypoint: ["/bin/bash", "-c"]
        command: |
          "
          # Wait for Kafka to be ready
          echo 'Waiting for Kafka to be ready...'
          cub kafka-ready -b kafka_broker:29092 1 180
          
          # Create topics
          echo 'Creating Kafka topics...'
          kafka-topics --create --if-not-exists --bootstrap-server kafka_broker:29092 --topic ids_processo --partitions 10 --replication-factor 1
          kafka-topics --create --if-not-exists --bootstrap-server kafka_broker:29092 --topic abas --partitions 10 --replication-factor 1
          echo 'Topics created.'
          
          sleep infinity
          "

    volumes:
      kafka_data:
      zookeeper_data:
      zookeeper_log:
    EOT
    
    # Install docker-compose
    curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Run Kafka and Zookeeper
    cd /home/ec2-user
    /usr/local/bin/docker-compose up -d
  EOF

  tags = {
    Name        = "${var.project}-${var.environment}-kafka"
    Environment = var.environment
    Project     = var.project
  }
}
