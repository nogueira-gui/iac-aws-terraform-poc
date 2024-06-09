#S3 BUCKET
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

#API GATEWAY
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.api_gateway_name}"
  description = "Exam Prep API Gateway for ${var.env}"
}

resource "aws_api_gateway_resource" "exams" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "exams"
}

resource "aws_api_gateway_resource" "exam_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.exams.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "get_exams" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.exams.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_exam" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.exam_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post_exam" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.exams.id
  http_method   = "POST"
  authorization = "NONE"
}

#LAMBDA FUNCTION

resource "aws_lambda_function" "lambda-exam" {
  function_name    = "lambda-exam-${var.env}"
  handler          = "lambda_function.handler"
  runtime          = var.runtime
  role             = aws_iam_role.role.arn
  filename         = "${path.module}/envs/${var.env}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/envs/${var.env}/lambda.zip")
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
    }
  }
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

#API GATEWAY LAMBDA INTEGRATION

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "lambda-exam-${var.env}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"

  depends_on = [ aws_lambda_function.lambda-exam ]
}

//Integrate with /exam/{id} endpoint  resource exam_id
resource "aws_api_gateway_integration" "lambda-gateway-integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.exam_id.id
  http_method = aws_api_gateway_method.get_exam.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.lambda-exam.invoke_arn

  depends_on = [ aws_lambda_function.lambda-exam ]
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.exam_id_get_lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "v1"
}