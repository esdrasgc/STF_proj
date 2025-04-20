variable "project" {
  description = "Project name"
}

variable "environment" {
  description = "Deployment environment"
}

variable "vpc_id" {
  description = "VPC ID where Kafka will be deployed"
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group" {
  description = "Security group ID for Kafka"
}

variable "instance_type" {
  description = "EC2 instance type for Kafka"
  default     = "t3.large"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instance"
}
