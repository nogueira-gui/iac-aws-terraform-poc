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

resource "aws_api_gateway_method" "get_exam" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.exam_id.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_gateway_authorizer.id
}

resource "aws_api_gateway_method" "get_exams" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.exams.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_gateway_authorizer.id
}

resource "aws_api_gateway_method" "post_exam" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.exams.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_gateway_authorizer.id
}

resource "aws_api_gateway_method" "delete_exam" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.exam_id.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_gateway_authorizer.id
}

# PARAMETER STORE
resource "aws_ssm_parameter" "my_secret_token" {
  name  = var.token_parameter_name
  type  = "String",
  value = "changeit"
  overwrite = true
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
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
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
resource "aws_api_gateway_integration" "lambda-gateway-integration-exam_id" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.exam_id.id
  http_method             = aws_api_gateway_method.get_exam.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-exam.invoke_arn

  depends_on = [aws_lambda_function.lambda-exam]
}

resource "aws_api_gateway_integration" "lambda-gateway-integration-exams" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.exams.id
  http_method             = aws_api_gateway_method.get_exams.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-exam.invoke_arn

  depends_on = [aws_lambda_function.lambda-exam]
}

resource "aws_api_gateway_integration" "lambda-gateway-integration-post-exam" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.exams.id
  http_method             = aws_api_gateway_method.post_exam.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-exam.invoke_arn

  depends_on = [aws_lambda_function.lambda-exam]
}

resource "aws_api_gateway_integration" "lambda-gateway-integration-delete-exam" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.exam_id.id
  http_method             = aws_api_gateway_method.delete_exam.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-exam.invoke_arn

  depends_on = [aws_lambda_function.lambda-exam]
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.env
  description = "Deployment for the ${var.env} environment"
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.exams.id,
      aws_api_gateway_method.get_exams.id,
      aws_api_gateway_integration.lambda-gateway-integration-exams.id,
      aws_api_gateway_method.post_exam.id,
      aws_api_gateway_integration.lambda-gateway-integration-post-exam.id,
      aws_api_gateway_resource.exam_id.id,
      aws_api_gateway_method.get_exam.id,
      aws_api_gateway_integration.lambda-gateway-integration-exam_id.id,
      aws_api_gateway_method.delete_exam.id,
      aws_api_gateway_integration.lambda-gateway-integration-delete-exam.id,
      aws_api_gateway_authorizer.api_gateway_authorizer.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Create IAM Role for Lambda Authorizer
resource "aws_iam_role" "role_lambda_authorizer" {
  name = "lambda-authorizer-role-${var.env}"
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

# fetch the account id and the region from the provider block
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

#Create IAM Policy for Lambda Authorizer
resource "aws_iam_policy" "policy_lambda_authorizer" {
  name        = "lambda-authorizer-policy-${var.env}"
  description = "A policy that allows the Lambda Authorizer function to interact with API Gateway"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "execute-api:Invoke"
        ],
        Resource = [
          "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*"
        ]
      }
    ]
  })
}

#Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "attachment_lambda_authorizer" {
  role       = aws_iam_role.role_lambda_authorizer.name
  policy_arn = aws_iam_policy.policy_lambda_authorizer.arn
}

#Create Lambda Authorizer
resource "aws_lambda_function" "lambda_authorizer" {
  function_name    = "lambda-authorizer-${var.env}"
  handler          = "lambda_authorizer.handler"
  runtime          = var.runtime
  role             = aws_iam_role.role_lambda_authorizer.arn
  filename         = "${path.module}/envs/${var.env}/lambda_authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/envs/${var.env}/lambda_authorizer.zip")
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      TOKEN_PARAMETER_NAME = aws_ssm_parameter.my_secret_token.name
    }
  
  }
}

#Create API Gateway Method with Lambda Authorizer
resource "aws_api_gateway_authorizer" "api_gateway_authorizer" {
  name                   = "lambda_authorizer_gateway_${var.env}"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  authorizer_uri         = aws_lambda_function.lambda_authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
}

data "aws_iam_policy_document" "invocation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "invocation_role" {
  name               = "api_gateway_auth_invocation"
  assume_role_policy = data.aws_iam_policy_document.invocation_assume_role.json
}

data "aws_iam_policy_document" "invocation_policy" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.lambda_authorizer.arn]
  }
}

resource "aws_iam_role_policy" "invocation_policy" {
  name   = "api_gateway_auth_invocation_policy"
  role   = aws_iam_role.invocation_role.id
  policy = data.aws_iam_policy_document.invocation_policy.json
}