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
  # Pass a public subnet ID instead of private_subnets
  # Assuming module.network.public_subnet_ids is a list of public subnet IDs
  subnet_id       = module.network.public_subnet_ids[0] 
  security_group  = module.network.mongodb_sg_id
  instance_type   = var.mongodb_instance_type
  ssh_key_name    = var.ssh_key_name
}

module "coleta_processo_us_east_1" {
  count  = contains(var.active_process_regions, "us-east-1") ? 1 : 0
  source = "./modules/coleta_processo"
  providers = { aws = aws.us_east_1 }

  project          = var.project
  environment      = var.environment
  regions          = ["us-east-1"]
  vpc_id           = module.network.vpc_id
  private_subnets  = module.network.private_subnets # Instances will be in private subnets
  security_group   = module.network.app_sg_id
  instance_type    = var.process_instance_type
  kafka_endpoint   = module.kafka.kafka_endpoint     # This is Kafka Host IP
  mongodb_endpoint = module.mongodb.mongodb_endpoint # This is Mongo Host IP
  mongodb_username = var.mongodb_username
  mongodb_password = var.mongodb_password
  mongodb_db       = var.mongodb_db
  ssh_key_name     = var.ssh_key_name
  replicas         = var.process_replicas_per_region
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_processo_us_west_2" {
  count  = contains(var.active_process_regions, "us-west-2") ? 1 : 0
  source = "./modules/coleta_processo"
  providers = { aws = aws.us_west_2 }

  project          = var.project
  environment      = var.environment
  regions          = ["us-west-2"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_processo_eu_west_1" {
  count  = contains(var.active_process_regions, "eu-west-1") ? 1 : 0
  source = "./modules/coleta_processo"
  providers = { aws = aws.eu_west_1 }

  project          = var.project
  environment      = var.environment
  regions          = ["eu-west-1"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_aba_us_east_1" {
  count  = contains(var.active_tabs_regions, "us-east-1") ? 1 : 0
  source = "./modules/coleta_aba"
  providers = { aws = aws.us_east_1 }

  project          = var.project
  environment      = var.environment
  regions          = ["us-east-1"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_aba_us_west_2" {
  count  = contains(var.active_tabs_regions, "us-west-2") ? 1 : 0
  source = "./modules/coleta_aba"
  providers = { aws = aws.us_west_2 }

  project          = var.project
  environment      = var.environment
  regions          = ["us-west-2"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_aba_eu_west_1" {
  count  = contains(var.active_tabs_regions, "eu-west-1") ? 1 : 0
  source = "./modules/coleta_aba"
  providers = { aws = aws.eu_west_1 }

  project          = var.project
  environment      = var.environment
  regions          = ["eu-west-1"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_aba_eu_central_1" {
  count  = contains(var.active_tabs_regions, "eu-central-1") ? 1 : 0
  source = "./modules/coleta_aba"
  providers = { aws = aws.eu_central_1 }

  project          = var.project
  environment      = var.environment
  regions          = ["eu-central-1"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_aba_ap_southeast_1" {
  count  = contains(var.active_tabs_regions, "ap-southeast-1") ? 1 : 0
  source = "./modules/coleta_aba"
  providers = { aws = aws.ap_southeast_1 }

  project          = var.project
  environment      = var.environment
  regions          = ["ap-southeast-1"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}

module "coleta_aba_sa_east_1" {
  count  = contains(var.active_tabs_regions, "sa-east-1") ? 1 : 0
  source = "./modules/coleta_aba"
  providers = { aws = aws.sa_east_1 }

  project          = var.project
  environment      = var.environment
  regions          = ["sa-east-1"]
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
  git_repo_url     = var.git_repo_url # Pass the Git repo URL
}
