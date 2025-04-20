provider "aws" {
  alias = "region_deployment"
}

# Get current region AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create IAM role for EC2 instances to allow cross-region access
resource "aws_iam_role" "coleta_processo_role" {
  name = "${var.project}-${var.environment}-coleta-processo-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-coleta-processo-role"
    Environment = var.environment
    Project     = var.project
  }
}

# Create IAM instance profile
resource "aws_iam_instance_profile" "coleta_processo_profile" {
  name = "${var.project}-${var.environment}-coleta-processo-profile"
  role = aws_iam_role.coleta_processo_role.name
}

# Deploy coleta_processo instances across regions
module "coleta_processo_regional" {
  source = "./regional"
  
  for_each = toset(var.regions)
  
  providers = {
    aws = aws.region_deployment
  }
  
  project            = var.project
  environment        = var.environment
  region             = each.key
  instance_type      = var.instance_type
  ami_id             = data.aws_ami.amazon_linux.id
  iam_profile        = aws_iam_instance_profile.coleta_processo_profile.name
  replicas           = var.replicas
  kafka_endpoint     = var.kafka_endpoint
  mongodb_endpoint   = var.mongodb_endpoint
  mongodb_username   = var.mongodb_username
  mongodb_password   = var.mongodb_password
  mongodb_db         = var.mongodb_db
  ssh_key_name       = var.ssh_key_name
}
