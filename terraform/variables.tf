variable "project" {
  description = "Project name"
  default     = "stf-proj"
}

variable "environment" {
  description = "Deployment environment"
  default     = "prod"
}

variable "aws_main_region" {
  description = "Main AWS region for base infrastructure (e.g., Kafka, MongoDB)"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "active_process_regions" {
  description = "List of AWS regions where coleta_processo should be actively deployed."
  type        = list(string)
  default     = ["us-east-1"] # Example default
}

variable "active_tabs_regions" {
  description = "List of AWS regions where coleta_aba should be actively deployed."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"] # Example default
}

variable "kafka_instance_type" {
  description = "EC2 instance type for Kafka/ZooKeeper"
  default     = "t3.medium"
}

variable "mongodb_instance_type" {
  description = "EC2 instance type for MongoDB"
  default     = "t3.medium"
}

variable "process_instance_type" {
  description = "EC2 instance type for coleta_processo"
  default     = "t3.small"
}

variable "tabs_instance_type" {
  description = "EC2 instance type for coleta_aba"
  default     = "t3.small"
}

variable "process_replicas_per_region" {
  description = "Number of coleta_processo instances per region"
  default     = 1
}

variable "tabs_replicas_per_region" {
  description = "Number of coleta_aba instances per region"
  default     = 1
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
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = "stf-proj-key"
}

variable "git_repo_url" {
  description = "URL of the Git repository containing the application code"
  type        = string
  default     = "https://github.com/esdrasgc/STF_proj/tree/master" # Replace with your actual repo URL
}
