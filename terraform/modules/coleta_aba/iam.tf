# Add CloudWatch policy to the role
resource "aws_iam_policy" "coleta_aba_cloudwatch" {
  name        = "${var.project}-${var.environment}-coleta-aba-cloudwatch-${var.regions[0]}"
  description = "IAM policy for CloudWatch Logs access for coleta_aba in ${var.regions[0]}"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "coleta_aba_cloudwatch" {
  role       = aws_iam_role.coleta_aba_role.name
  policy_arn = aws_iam_policy.coleta_aba_cloudwatch.arn
}
