provider "aws" {
  region = var.aws_main_region
}

module "network" {
  source      = "./modules/network"
  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "kafka" {
  source           = "./modules/kafka"
  project          = var.project
  environment      = var.environment
  vpc_id           = module.network.vpc_id
  private_subnets  = module.network.private_subnets
  security_group   = module.network.kafka_sg_id
  instance_type    = var.kafka_instance_type
  ssh_key_name     = var.ssh_key_name
}

module "mongodb" {
  source          = "./modules/mongodb"
  project         = var.project
  environment     = var.environment
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
  security_group  = module.network.mongodb_sg_id
  instance_type   = var.mongodb_instance_type
  ssh_key_name    = var.ssh_key_name
}

module "coleta_processo" {
  source           = "./modules/coleta_processo"
  project          = var.project
  environment      = var.environment
  regions          = var.process_collection_regions
  vpc_id           = module.network.vpc_id
  private_subnets  = module.network.private_subnets
  security_group   = module.network.app_sg_id
  instance_type    = var.process_instance_type
  kafka_endpoint   = module.kafka.kafka_endpoint
  mongodb_endpoint = module.mongodb.mongodb_endpoint
  mongodb_username = var.mongodb_username
  mongodb_password = var.mongodb_password
  mongodb_db       = var.mongodb_db
  ssh_key_name     = var.ssh_key_name
  replicas         = var.process_replicas_per_region
}

module "coleta_aba" {
  source           = "./modules/coleta_aba"
  project          = var.project
  environment      = var.environment
  regions          = var.tabs_collection_regions
  vpc_id           = module.network.vpc_id
  private_subnets  = module.network.private_subnets
  security_group   = module.network.app_sg_id
  instance_type    = var.tabs_instance_type
  kafka_endpoint   = module.kafka.kafka_endpoint
  mongodb_endpoint = module.mongodb.mongodb_endpoint
  mongodb_username = var.mongodb_username
  mongodb_password = var.mongodb_password
  mongodb_db       = var.mongodb_db
  ssh_key_name     = var.ssh_key_name
  replicas         = var.tabs_replicas_per_region
}
