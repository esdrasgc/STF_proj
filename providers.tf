terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

variable "aws_main_region" {
  description = "Main AWS region for resource deployment"
  type        = string
  default     = "us-east-1"  # You can change this default value as needed
}

# Default provider for the main region
provider "aws" {
  region = var.aws_main_region
}

# Define individual provider aliases for each region
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "eu_central_1"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "sa_east_1"
  region = "sa-east-1"
}