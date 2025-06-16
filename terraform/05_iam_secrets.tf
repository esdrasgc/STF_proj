# Este arquivo cria as permissões (IAM) e o local para guardar segredos (Secrets Manager).

# --- 1. IAM Role e Policy para as instâncias EC2 ---
# Esta policy define o que as instâncias EC2 (tanto Kafka quanto coletores) podem fazer.
# A permissão para acessar o ECR foi REMOVIDA.
data "aws_iam_policy_document" "ec2_permissions" {
  statement {
    sid       = "AllowSecretsManagerAccess"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.app_secrets.arn]
  }
  
  statement {
    sid       = "AllowCloudWatchLogs"
    actions   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "ec2_policy" {
  name   = "${var.project_name}-ec2-policy"
  policy = data.aws_iam_policy_document.ec2_permissions.json
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# --- 2. AWS Secrets Manager ---
# Cria um segredo para armazenar dados sensíveis como a string de conexão do MongoDB.
resource "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.project_name}/app-secrets"
  description = "Segredos para a aplicação de coleta"
}

# Adiciona uma versão inicial ao segredo com um valor placeholder.
# VOCÊ DEVE ATUALIZAR ESTE VALOR MANUALMENTE no console da AWS após a criação!
resource "aws_secretsmanager_secret_version" "app_secrets_version" {
  secret_id     = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    MONGO_URI = "mongodb+srv://usuario:senha@cluster.mongodb.net/seu_db?retryWrites=true&w=majority"
  })
}
