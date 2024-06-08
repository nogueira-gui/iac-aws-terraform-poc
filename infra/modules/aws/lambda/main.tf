resource "aws_lambda_function" "lambda-exam" {
  function_name    = "lambda-exam-${var.env}"
  handler          = "lambda_function.handler"
  runtime          = var.runtime
  role             = aws_iam_role.role.arn
  filename         = "infra/envs/${var.env}/lambda.zip"
  source_code_hash = filebase64sha256("infra/envs/${var.env}/lambda.zip")
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.attachment
  ]
}

resource "aws_iam_role" "role" {
  name = "lambda-exam-role-${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "policy" {
  name        = "lambda-exam-policy-${var.env}"
  description = "A policy that allows the Lambda function to interact with S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
