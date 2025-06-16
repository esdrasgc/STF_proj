#!/bin/bash
# Script de inicialização para TODAS as instâncias coletoras.
# Ele recebe o nome da imagem pública do Docker Hub do Terraform.

# --- 1. Instalação de Dependências ---
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
yum install -y jq

# --- 3. Busca de Segredos e Configurações ---
# A variável ${aws_region} é passada pelo Terraform (região central).
SECRETS=$(aws secretsmanager get-secret-value --secret-id "${secret_name}" --region "${aws_region}" --query SecretString --output text)

# Extrai os valores do JSON de segredos.
MONGO_URI=$(echo $SECRETS | jq -r .MONGO_URI)
# Adicione outras variáveis de ambiente aqui se necessário
# MONGO_USER=$(echo $SECRETS | jq -r .MONGO_USER)
# MONGO_PASS=$(echo $SECRETS | jq -r .MONGO_PASS)

# --- 4. Execução do Contêiner Docker ---
# A variável ${docker_image_name} é passada pelo Terraform para especificar a imagem correta.
# A flag --restart=always garante a resiliência do contêiner.
docker run -d --restart=always \
  -e KAFKA_BROKER_HOST="${kafka_bootstrap_servers}" \
  -e MONGO_URI="$MONGO_URI" \
  --log-driver=awslogs \
  --log-opt awslogs-group=${var.project_name}-collectors \
  --log-opt awslogs-region=$EC2_REGION \
  --log-opt awslogs-stream=$EC2_REGION-$(hostname) \
  ${docker_image_name}:latest
