terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [aws.region_deployment]
    }
  }
  required_version = ">= 1.0.0"
}

# Default provider for the main region
provider "aws" {
  region = var.primary_region
}secondary

# Provider for secondary region
provider "aws" {
  alias  = "secondary_region"
  region = var.secondary_region
}

# Provider configurations for process collection regions
provider "aws" {
  alias  = "region_deployment"
  region = "us-east-1" # This will be overridden by the module
}

# Define provider configurations for each region
locals {
  all_regions = distinct(concat(var.process_collection_regions, var.tabs_collection_regions))
}

# Create provider configurations for each region dynamically
module "providers" {
  source = "./modules/providers"
  regions = local.all_regions
}

module "coleta_aba_regional" {
  source = "./regional"
  
  providers = {
    aws = aws.region_deployment
  }
  
  # other variables...
}

module "coleta_processo" {
  source = "./modules/coleta_processo"
  
  providers = {
    aws = aws
  }
  
  # other variables...
}

module "coleta_aba" {
  source = "./modules/coleta_aba"
  
  providers = {
    aws = aws.secondary_region
  }
  
  # other variables...
}
