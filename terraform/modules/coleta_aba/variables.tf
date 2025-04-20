variable "project" {
  description = "Project name"
}

variable "environment" {
  description = "Deployment environment"
}

variable "vpc_id" {
  description = "VPC ID for workers"
}

variable "regions" {
  description = "List of AWS regions to deploy instances"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group" {
  description = "Security group ID for worker instances"
}

variable "instance_type" {
  description = "EC2 instance type for worker instances"
}

variable "kafka_endpoint" {
  description = "Kafka broker endpoint"
}

variable "mongodb_endpoint" {
  description = "MongoDB endpoint"
}

variable "mongodb_username" {
  description = "MongoDB username"
}

variable "mongodb_password" {
  description = "MongoDB password"
  sensitive   = true
}

variable "mongodb_db" {
  description = "MongoDB database name"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instances"
}

variable "replicas" {
  description = "Number of replicas per region"
  default     = 5
}
