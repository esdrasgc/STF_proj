# Define a instância e a segurança para o servidor Kafka.

# Obtém a AMI mais recente do Amazon Linux 2.
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group para a instância Kafka.
resource "aws_security_group" "kafka_sg" {
  name        = "${var.project_name}-kafka-sg"
  description = "Permite tráfego para Kafka"
  vpc_id      = module.vpc.vpc_id

  # Permite tráfego na porta 9092 a partir de QUALQUER LUGAR DENTRO da VPC.
  # Isso é seguro porque a VPC é uma rede privada e isolada.
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    description = "Allow Kafka traffic from within the VPC"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Definição da instância EC2 para o servidor Kafka.
resource "aws_instance" "kafka_server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.kafka_instance_type
  subnet_id                   = module.vpc.private_subnets[0] # Coloca na sub-rede privada
  vpc_security_group_ids      = [aws_security_group.kafka_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data = templatefile("${path.module}/scripts/kafka_bootstrap.sh", {})

  tags = {
    Name = "${var.project_name}-kafka-server"
  }
}
