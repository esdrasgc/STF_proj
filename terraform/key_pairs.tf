# Read the public key from file
data "local_file" "ssh_public_key" {
  filename = "${path.module}/scripts/${var.ssh_key_name}.pub"
  # Note: you need to manually create this file by running:
  # ssh-keygen -y -f scripts/stf-proj-key.pem > scripts/stf-proj-key.pub
}

# Default region key pair
resource "aws_key_pair" "main_key_pair" {
  key_name   = var.ssh_key_name
  public_key = data.local_file.ssh_public_key.content
}

# us-east-1 region key pair - only create if different from main region
resource "aws_key_pair" "us_east_1" {
  count      = var.aws_main_region == "us-east-1" ? 0 : 1
  provider   = aws.us_east_1
  key_name   = var.ssh_key_name
  public_key = data.local_file.ssh_public_key.content
}

# us-west-2 region key pair - only create if different from main region
resource "aws_key_pair" "us_west_2" {
  count      = var.aws_main_region == "us-west-2" ? 0 : 1
  provider   = aws.us_west_2
  key_name   = var.ssh_key_name
  public_key = data.local_file.ssh_public_key.content
}

# eu-west-1 region key pair - only create if different from main region
resource "aws_key_pair" "eu_west_1" {
  count      = var.aws_main_region == "eu-west-1" ? 0 : 1
  provider   = aws.eu_west_1
  key_name   = var.ssh_key_name
  public_key = data.local_file.ssh_public_key.content
}

# eu-central-1 region key pair - only create if different from main region
resource "aws_key_pair" "eu_central_1" {
  count      = var.aws_main_region == "eu-central-1" ? 0 : 1
  provider   = aws.eu_central_1
  key_name   = var.ssh_key_name
  public_key = data.local_file.ssh_public_key.content
}

# ap-southeast-1 region key pair - only create if different from main region
resource "aws_key_pair" "ap_southeast_1" {
  count      = var.aws_main_region == "ap-southeast-1" ? 0 : 1
  provider   = aws.ap_southeast_1
  key_name   = var.ssh_key_name
  public_key = data.local_file.ssh_public_key.content
}

# sa-east-1 region key pair - only create if different from main region
resource "aws_key_pair" "sa_east_1" {
  count      = var.aws_main_region == "sa-east-1" ? 0 : 1
  provider   = aws.sa_east_1
  key_name   = var.ssh_key_name
  public_key = data.local_file.ssh_public_key.content
}
