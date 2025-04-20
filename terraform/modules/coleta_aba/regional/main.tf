# Deploy M replicas of coleta_aba in a specific region
resource "aws_instance" "coleta_aba" {
  count         = var.replicas
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  
  iam_instance_profile = var.iam_profile

  user_data = templatefile("${path.module}/user_data.tpl", {
    kafka_endpoint   = var.kafka_endpoint
    mongodb_endpoint = var.mongodb_endpoint
    mongodb_username = var.mongodb_username
    mongodb_password = var.mongodb_password
    mongodb_db       = var.mongodb_db
    region           = var.region
    replica_id       = count.index
  })

  tags = {
    Name        = "${var.project}-${var.environment}-coleta-aba-${var.region}-${count.index}"
    Environment = var.environment
    Project     = var.project
    Region      = var.region
  }

  lifecycle {
    create_before_destroy = true
  }
}
