variable "project" {
  description = "Project name"
}

variable "environment" {
  description = "Deployment environment"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
