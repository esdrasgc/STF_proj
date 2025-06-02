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
  name = "${var.project}-${var.environment}-coleta-processo-role-${var.regions[0]}"

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
    Name        = "${var.project}-${var.environment}-coleta-processo-role-${var.regions[0]}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "coleta_processo_cloudwatch_attach" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.coleta_processo_role.name
}

# Create IAM instance profile
resource "aws_iam_instance_profile" "coleta_processo_profile" {
  name = "${var.project}-${var.environment}-coleta-processo-profile-${var.regions[0]}"
  role = aws_iam_role.coleta_processo_role.name
}

# Deploy coleta_processo instances across regions
module "coleta_processo_regional" {
  source = "./regional"
  
  for_each = toset(var.regions)
  
  project                = var.project
  environment            = var.environment
  region                 = each.key
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnets # Pass private_subnets as subnet_ids
  instance_type          = var.instance_type
  app_security_group_id  = var.security_group
  iam_instance_profile_name = aws_iam_instance_profile.coleta_processo_profile.name
  ssh_key_name           = var.ssh_key_name
  replicas_per_region    = var.replicas
  kafka_broker_host      = var.kafka_endpoint
  mongodb_host           = var.mongodb_endpoint
  mongodb_username       = var.mongodb_username
  mongodb_password       = var.mongodb_password
  mongodb_db             = var.mongodb_db
  git_repo_url           = var.git_repo_url
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
