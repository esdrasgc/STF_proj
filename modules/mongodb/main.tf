variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
# ... other variables ...

# Determine architecture based on instance type prefix (t4g -> arm64)
locals {
  instance_architecture = substr(var.instance_type, 0, 3) == "t4g" ? "arm64" : "x86_64"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # Adjust pattern if needed, e.g., for AL2023: "al2023-ami-*-kernel-*-gp2"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Add architecture filter
  filter {
    name   = "architecture"
    values = [local.instance_architecture]
  }
}

resource "aws_instance" "mongodb" {
  ami           = data.aws_ami.amazon_linux.id # Use the dynamically found AMI
  instance_type = var.instance_type
  # ... rest of instance config ...
  # Ensure subnet_id, security_group, key_name etc. are correctly defined
}

# ... other resources ...

output "mongodb_endpoint" {
  description = "Private IP of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip # Or public_ip if needed
}
