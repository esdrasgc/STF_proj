# Define a versão do Terraform e os provedores necessários.
# É uma boa prática fixar as versões para evitar que atualizações inesperadas quebrem seu código.
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # O provedor do MongoDB Atlas é necessário se você quiser gerenciar o Atlas via Terraform.
    # Você precisará configurar as chaves de API do Atlas como variáveis de ambiente.
    # mongodbatlas = {
    #   source = "mongodb/mongodbatlas"
    #   version = "~> 1.15"
    # }
  }
}

# Configuração do provedor principal da AWS.
# Ele será usado para a "região central", onde o Kafka e o MongoDB Atlas estarão.
provider "aws" {
  region = var.central_region
}

# O provedor do MongoDB Atlas. Descomente se for usar.
# provider "mongodbatlas" {
#   public_key  = var.atlas_public_key
#   private_key = var.atlas_private_key
# }
