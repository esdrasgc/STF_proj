variable "project" {
  description = "Project name"
}

variable "environment" {
  description = "Deployment environment"
}

variable "vpc_id" {
  description = "VPC ID where MongoDB will be deployed"
}

variable "subnet_id" {
  description = "ID of the public subnet to deploy MongoDB into"
  type        = string
}

variable "security_group" {
  description = "Security group ID for MongoDB"
}

variable "instance_type" {
  description = "EC2 instance type for MongoDB"
  default     = "t3.large"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instance"
}
