# Este arquivo cria as permissões e segredos.
# A única mudança é a remoção da permissão para ECR.

# --- 1. IAM Role e Policy para as instâncias EC2 ---
data "aws_iam_policy_document" "ec2_permissions" {
  statement {
    sid       = "AllowSecretsManagerAccess"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.app_secrets.arn]
  }

  statement {
    sid     = "AllowCloudWatchLogs"
    actions = [
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
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
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
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.project_name}/app-secrets"
  description = "Segredos para a aplicação de coleta"
}

resource "aws_secretsmanager_secret_version" "app_secrets_version" {
  secret_id     = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    MONGO_URI = format(
      "mongodb+srv://%s:%s@%s/%s?retryWrites=true&w=majority",
      var.mongo_user,
      var.mongo_password,
      var.mongo_cluster_url,
      var.mongo_database_name
    )
  })
}
