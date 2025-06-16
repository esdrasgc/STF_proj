# Este arquivo cria os Launch Templates e Auto Scaling Groups para
# todas as 10 instâncias coletoras.

# --- 1. Security Group para os Coletores ---
# Um SG por VPC de coletor. Ele só precisa permitir todo o tráfego de saída.
# A comunicação de entrada é gerenciada pelas rotas e não precisa de regras aqui.
resource "aws_security_group" "collector_sg" {
  for_each = module.collector_vpcs
  provider = aws.collector_regions[replace(each.key, "-", "_")]

  name        = "${var.project_name}-collector-sg"
  description = "Security Group para as instâncias coletoras"
  vpc_id      = each.value.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-collector-sg"
  }
}


# --- 2. Launch Templates (Moldes para as Instâncias) ---

# Launch Template para 'coleta-processo'
resource "aws_launch_template" "coleta_processo_lt" {
  name                   = "${var.project_name}-coleta-processo-lt"
  image_id               = data.aws_ami.amazon_linux_2.id # Usando a mesma AMI
  instance_type          = var.collector_instance_type
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }
  
  # O user data agora passa o nome da imagem pública do Docker Hub.
  user_data = base64encode(templatefile("${path.module}/scripts/collector_bootstrap.sh", {
    aws_region       = var.central_region
    secret_name      = aws_secretsmanager_secret.app_secrets.name
    kafka_bootstrap_servers = "${aws_instance.kafka_server.private_ip}:9092"
    docker_image_name    = "esdrasgc/coleta-processo"
  }))

  # Tags que serão aplicadas à instância
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-coleta-processo"
    }
  }
}

# Launch Template para 'coleta-aba'
resource "aws_launch_template" "coleta_aba_lt" {
  name                   = "${var.project_name}-coleta-aba-lt"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = var.collector_instance_type
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  user_data = base64encode(templatefile("${path.module}/scripts/collector_bootstrap.sh", {
    aws_region       = var.central_region
    secret_name      = aws_secretsmanager_secret.app_secrets.name
    kafka_bootstrap_servers = "${aws_instance.kafka_server.private_ip}:9092"
    docker_image_name    = "esdrasgc/coleta-aba"
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-coleta-aba"
    }
  }
}


# --- 3. Auto Scaling Groups (Garantem que a instância rode) ---

# Cria um ASG para cada região da lista 'processo_collector_regions'
resource "aws_autoscaling_group" "processo_asg" {
  for_each = toset(var.processo_collector_regions)
  provider = aws.collector_regions[replace(each.key, "-", "_")]

  name                      = "${var.project_name}-processo-asg-${each.key}"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  
  # Sub-redes na região correta
  vpc_zone_identifier       = module.collector_vpcs[each.key].private_subnets
  
  launch_template {
    id      = aws_launch_template.coleta_processo_lt.id
    version = "$Latest"
  }
}

# Cria um ASG para cada região da lista 'aba_collector_regions'
resource "aws_autoscaling_group" "aba_asg" {
  for_each = toset(var.aba_collector_regions)
  provider = aws.collector_regions[replace(each.key, "-", "_")]

  name                      = "${var.project_name}-aba-asg-${each.key}"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"

  vpc_zone_identifier       = module.collector_vpcs[each.key].private_subnets
  
  launch_template {
    id      = aws_launch_template.coleta_aba_lt.id
    version = "$Latest"
  }
}
