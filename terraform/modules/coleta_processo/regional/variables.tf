variable "project" {
  description = "Project name"
}

variable "environment" {
  description = "Deployment environment"
}

variable "region" {
  description = "AWS region for deployment"
}

variable "instance_type" {
  description = "EC2 instance type for worker instances"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
}

variable "iam_profile" {
  description = "IAM instance profile name"
}

variable "replicas" {
  description = "Number of replicas to deploy"
  default     = 1
}

variable "kafka_endpoint" {
  description = "Kafka broker endpoint"
}

variable "mongodb_endpoint" {
  description = "MongoDB endpoint"
}

variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
  sensitive   = true
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
}

variable "mongodb_db" {
  description = "MongoDB database name"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
}

variable "replicas_per_region" {
  description = "Number of instances to create per region"
  type        = number
}

variable "kafka_broker_host" {
  description = "Kafka broker host IP"
  type        = string
}

variable "mongodb_host" {
  description = "MongoDB host IP"
  type        = string
}

variable "git_repo_url" {
  description = "URL of the Git repository for the application code"
  type        = string
}
