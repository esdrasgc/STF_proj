# Este arquivo configura toda a rede. É o mais complexo, pois lida com
# múltiplas regiões e a comunicação entre elas.

# --- 1. Provedores AWS para cada região dos coletores ---
# Precisamos de um provedor para cada região onde implantaremos um coletor,
# pois recursos como VPCs são regionais.
provider "aws" {
  alias  = "central"
  region = var.central_region
}

# Cria um provedor para cada região de coletor para podermos criar VPCs nelas.
# O for_each garante que não criamos provedores duplicados para a mesma região.
resource "aws_provider" "collector_regions" {
  for_each = toset(concat(var.processo_collector_regions, var.aba_collector_regions))
  alias    = replace(each.key, "-", "_") # Alias precisa ser um identificador válido
  region   = each.key
}

# --- 2. Rede Central (Onde o Kafka e o Atlas estão) ---
module "central_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"
  providers = {
    aws = aws.central
  }

  name = "${var.project_name}-central-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.central_region}a", "${var.central_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Mais barato para este cenário

  tags = {
    Terraform   = "true"
    Environment = "production"
    Project     = var.project_name
  }
}

# --- 3. Redes dos Coletores (Uma VPC por região) ---
module "collector_vpcs" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"
  for_each = toset(concat(var.processo_collector_regions, var.aba_collector_regions))
  providers = {
    aws = aws.collector_regions[replace(each.key, "-", "_")]
  }

  name = "${var.project_name}-collector-vpc-${each.key}"
  cidr = "10.1.0.0/16" # O módulo VPC gerencia IPs não conflitantes

  azs             = ["${each.key}a", "${each.key}b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  
  # Não precisamos de sub-redes públicas ou NAT Gateway nos coletores.
  # A comunicação com a internet será via Transit Gateway na VPC central.
  enable_nat_gateway = false
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "production"
    Project     = var.project_name
    Region      = each.key
  }
}


# --- 4. Conectividade Global com Transit Gateway ---
resource "aws_ec2_transit_gateway" "tgw" {
  provider = aws.central # Criamos o TGW na região central
  description = "Transit Gateway para conectar todas as VPCs do projeto"
  
  # Permite que o roteamento entre as VPCs seja configurado automaticamente.
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "${var.project_name}-tgw"
  }
}

# Anexa a VPC central ao Transit Gateway.
resource "aws_ec2_transit_gateway_vpc_attachment" "central_attachment" {
  provider       = aws.central
  subnet_ids     = module.central_vpc.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id         = module.central_vpc.vpc_id
  tags = { Name = "${var.project_name}-tgw-attachment-central" }
}

# Anexa cada VPC de coletor ao Transit Gateway.
resource "aws_ec2_transit_gateway_vpc_attachment" "collector_attachments" {
  for_each = module.collector_vpcs
  provider = aws.collector_regions[replace(each.key, "-", "_")]

  subnet_ids         = each.value.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = each.value.vpc_id
  tags = { Name = "${var.project_name}-tgw-attachment-${each.key}" }
}

# --- 5. Roteamento ---
# Adiciona uma rota na VPC central para que ela saiba como alcançar as VPCs dos coletores.
resource "aws_route" "central_to_tgw" {
  provider = aws.central
  route_table_id         = module.central_vpc.private_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8" # Rota ampla para cobrir todas as VPCs
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Adiciona uma rota em cada VPC de coletor para que elas possam acessar a internet e a VPC central.
resource "aws_route" "collectors_to_tgw" {
  for_each = module.collector_vpcs
  provider = aws.collector_regions[replace(each.key, "-", "_")]

  route_table_id         = each.value.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}
