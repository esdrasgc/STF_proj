resource "aws_security_group" "mongodb_sg" {
  name        = "${var.project}-${var.environment}-mongodb-sg"
  description = "Security group for MongoDB instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MongoDB from anywhere (Public)"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Allows access from any IP
  }

  ingress {
    description = "SSH from anywhere (Public)" # If you need SSH access directly
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Allows access from any IP
  }
  
  # You might want to keep an ingress rule for internal VPC access if other services need it
  ingress {
    description = "MongoDB from within VPC"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] # Or more specific security groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-mongodb-sg"
    Environment = var.environment
    Project     = var.project
  }
}