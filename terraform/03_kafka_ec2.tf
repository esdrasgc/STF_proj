# --- Configuração da Instância EC2 para o Kafka Auto-Gerenciado ---

# Security Group para a instância Kafka.
# Permite acesso ao Zookeeper (2181) e Kafka (9092) apenas de dentro da nossa rede.
# Permite todo o tráfego de saída para que a instância possa baixar pacotes e imagens.
resource "aws_security_group" "kafka_sg" {
  name        = "${var.project_name}-kafka-sg"
  description = "Permite tráfego para Kafka e Zookeeper"
  vpc_id      = aws_vpc.central_vpc.id # Assumindo que a VPC central está em outro arquivo

  # TODO: Adicionar regras de entrada (ingress) que permitam o tráfego
  # a partir dos CIDR blocks das VPCs dos coletores.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-kafka-sg"
  }
}

# Obtém a AMI mais recente do Amazon Linux 2.
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Script de inicialização (User Data) para a instância Kafka.
# Este script automatiza toda a configuração da instância.
data "template_file" "kafka_user_data" {
  template = file("${path.module}/scripts/kafka_bootstrap.sh")
}

resource "aws_instance" "kafka_server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.kafka_instance_type
  subnet_id                   = aws_subnet.central_private.id # Assumindo subnet privada
  security_groups             = [aws_security_group.kafka_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name # Assumindo perfil IAM
  user_data_base64            = base64encode(data.template_file.kafka_user_data.rendered)
  associate_public_ip_address = false # Instância em sub-rede privada

  # Importante: Protege a instância contra terminação acidental.
  disable_api_termination = true

  tags = {
    Name = "${var.project_name}-kafka-server"
  }
}
