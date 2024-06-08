
module "aws-s3-bucket" {
  source = "./modules/aws/s3"
  bucket_name = var.bucket_name
}

module "aws-api-gateway" {
  source = "./modules/aws/apigateway"
  api_gateway_name = var.api_gateway_name
  env = var.env
}
module "aws-lambda-exam" {
  source = "./modules/aws/lambda"
  env = var.env
  runtime = var.runtime
  timeout = var.timeout
  memory_size = var.memory_size
  bucket_name = var.bucket_name
  api_gateway_name = var.api_gateway_name
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.aws-lambda-exam.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws-api-gateway.api.execution_arn}/*/*/*"
}

//Integrate with /exam/{id} endpoint  resource exam_id
resource "aws_api_gateway_integration" "lambda-gateway-integration" {
  rest_api_id             = aws-api-gateway.api.id
  resource_id             = aws-api-gateway.exam_id.id
  http_method             = aws-api-gateway.get_exam.method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.aws-lambda-exam.invoke_arn
}