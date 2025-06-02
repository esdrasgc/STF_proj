variable "regions" {
  description = "List containing the AWS region for this module instance"
  type        = list(string)
  validation {
    condition     = length(var.regions) == 1
    error_message = "The regions variable must contain exactly one region string."
  }
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group" {
  description = "Security group ID for the instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "kafka_endpoint" {
  description = "Kafka broker endpoint"
  type        = string
}

variable "mongodb_endpoint" {
  description = "MongoDB endpoint"
  type        = string
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

variable "replicas" {
  description = "Number of instances to create"
  type        = number
}
