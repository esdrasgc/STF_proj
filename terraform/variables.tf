variable "project" {
  description = "Project name"
  default     = "stf-proj"
}

variable "environment" {
  description = "Deployment environment"
  default     = "prod"
}

variable "aws_main_region" {
  description = "Main AWS region for base infrastructure"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "process_collection_regions" {
  description = "AWS regions where coleta_processo should be deployed"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "eu-west-1"]
}

variable "tabs_collection_regions" {
  description = "AWS regions where coleta_aba should be deployed"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "eu-central-1", "ap-southeast-1", "sa-east-1"]
}

variable "kafka_instance_type" {
  description = "EC2 instance type for Kafka/ZooKeeper"
  default     = "t3.large"
}

variable "mongodb_instance_type" {
  description = "EC2 instance type for MongoDB"
  default     = "t3.large"
}

variable "process_instance_type" {
  description = "EC2 instance type for coleta_processo"
  default     = "t3.medium"
}

variable "tabs_instance_type" {
  description = "EC2 instance type for coleta_aba"
  default     = "t3.medium"
}

variable "process_replicas_per_region" {
  description = "Number of coleta_processo instances per region"
  default     = 1
}

variable "tabs_replicas_per_region" {
  description = "Number of coleta_aba instances per region"
  default     = 5
}

variable "mongodb_username" {
  description = "MongoDB root username"
  default     = "root"
  sensitive   = true
}

variable "mongodb_password" {
  description = "MongoDB root password"
  sensitive   = true
}

variable "mongodb_db" {
  description = "MongoDB database name"
  default     = "stf_data"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instances"
  default     = "stf-proj-key"
}
