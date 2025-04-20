# Add CloudWatch policy to the role
resource "aws_iam_policy" "coleta_aba_cloudwatch" {
  name        = "${var.project}-${var.environment}-coleta-aba-cloudwatch"
  description = "Allow coleta_aba instances to log to CloudWatch"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeTags"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "coleta_aba_cloudwatch" {
  role       = aws_iam_role.coleta_aba_role.name
  policy_arn = aws_iam_policy.coleta_aba_cloudwatch.arn
}
