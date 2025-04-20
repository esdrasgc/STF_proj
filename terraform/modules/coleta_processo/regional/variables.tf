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
