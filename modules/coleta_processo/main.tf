# ... potentially other resources like data "aws_ami" ...

resource "aws_iam_role" "coleta_processo_role" {
  name               = "${var.project}-${var.environment}-coleta-processo-role-${var.regions[0]}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name        = "${var.project}-${var.environment}-coleta-processo-role-${var.regions[0]}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "coleta_processo_cloudwatch_attach" {
  role       = aws_iam_role.coleta_processo_role.name
  policy_arn = aws_iam_policy.coleta_processo_cloudwatch.arn
}

resource "aws_iam_instance_profile" "coleta_processo_profile" {
  name = "${var.project}-${var.environment}-coleta-processo-profile-${var.regions[0]}"
  role = aws_iam_role.coleta_processo_role.name
}

# Example aws_instance resource (assuming it exists in this module)
# resource "aws_instance" "coleta_processo_instance" {
#   count         = var.replicas
#   ami           = data.aws_ami.amazon_linux.id # Make sure AMI data source exists and is correct
#   instance_type = var.instance_type
#   subnet_id     = element(var.private_subnets, count.index % length(var.private_subnets))
#   vpc_security_group_ids = [var.security_group]
#   key_name      = var.ssh_key_name
#   iam_instance_profile = aws_iam_instance_profile.coleta_processo_profile.name

#   tags = {
#     Name        = "${var.project}-${var.environment}-coleta-processo-${var.regions[0]}-${count.index}"
#     Environment = var.environment
#     Project     = var.project
#   }
#   # Add user_data or other configurations as needed
# }

# ... other resources ...
