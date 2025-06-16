# Define a versão do Terraform e o provedor principal da AWS.
# Como agora usamos uma única região, este arquivo se torna muito mais simples.
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuração do único provedor AWS que vamos usar.
provider "aws" {
  region = var.aws_region
}
