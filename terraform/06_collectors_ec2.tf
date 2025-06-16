# Define as instâncias coletoras, seus IPs públicos e segurança.

# --- 1. Security Group para os Coletores ---
resource "aws_security_group" "collector_sg" {
  name        = "${var.project_name}-collector-sg"
  description = "Security Group para as instâncias coletoras"
  vpc_id      = module.vpc.vpc_id

  # Não permite NENHUM tráfego de entrada. As instâncias só fazem requisições para fora.
  # (Você pode adicionar uma regra de entrada para SSH a partir do seu IP se precisar de acesso)

  # Permite todo o tráfego de saída.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 2. Instâncias Coletoras ---

# Cria 2 instâncias para 'coleta-processo'
resource "aws_instance" "coleta_processo" {
  count = var.processo_collector_count

  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.collector_instance_type
  # Distribui as instâncias pelas sub-redes públicas disponíveis
  subnet_id                   = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  vpc_security_group_ids      = [aws_security_group.collector_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true # Associa um IP público temporário na criação

  user_data = templatefile("${path.module}/scripts/collector_bootstrap.sh", {
    aws_region              = var.aws_region
    secret_name             = aws_secretsmanager_secret.app_secrets.name
    kafka_bootstrap_servers = "${aws_instance.kafka_server.private_ip}:9092"
    docker_image_name       = "esdrasgc/coleta-processo"
  })

  tags = {
    Name = "${var.project_name}-coleta-processo-${count.index + 1}"
    Type = "coleta-processo"
  }
}

# Cria 8 instâncias para 'coleta-aba'
resource "aws_instance" "coleta_aba" {
  count = var.aba_collector_count

  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.collector_instance_type
  subnet_id                   = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  vpc_security_group_ids      = [aws_security_group.collector_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/scripts/collector_bootstrap.sh", {
    aws_region              = var.aws_region
    secret_name             = aws_secretsmanager_secret.app_secrets.name
    kafka_bootstrap_servers = "${aws_instance.kafka_server.private_ip}:9092"
    docker_image_name       = "esdrasgc/coleta-aba"
  })

  tags = {
    Name = "${var.project_name}-coleta-aba-${count.index + 1}"
    Type = "coleta-aba"
  }
}

# --- 3. IPs Públicos Estáticos (Elastic IPs) ---

# Associa um IP Elástico a cada instância 'coleta-processo'
resource "aws_eip_association" "processo_eip_assoc" {
  count       = var.processo_collector_count
  instance_id = aws_instance.coleta_processo[count.index].id
  # Cria um novo Elastic IP implicitamente e o associa.
}

# Associa um IP Elástico a cada instância 'coleta-aba'
resource "aws_eip_association" "aba_eip_assoc" {
  count       = var.aba_collector_count
  instance_id = aws_instance.coleta_aba[count.index].id
}
