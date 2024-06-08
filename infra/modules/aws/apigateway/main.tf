//the gateway should have 3 endpoints GET /exams, GET /exams/{id}, POST /exams 

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
