# Este arquivo agora define apenas UMA VPC onde todos os recursos viverão.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  # Criamos sub-redes em duas Zonas de Disponibilidade para resiliência.
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"] # Para o Kafka
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"] # Para os Coletores

  # Habilita um único NAT Gateway para que a instância privada do Kafka
  # possa acessar a internet para baixar pacotes, se necessário.
  # Os coletores usarão o Internet Gateway.
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "production"
    Project     = var.project_name
  }
}
