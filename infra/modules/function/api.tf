# -------------------------------------
# API Resources
# -------------------------------------
resource "aws_api_gateway_resource" "function" {
  rest_api_id = var.api_id
  parent_id   = var.api_root_resource_id
  path_part   = "verify"
}

resource "aws_api_gateway_resource" "function_v1" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.function.id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "function_v1_proxy" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.function_v1.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "function_v1_proxy_get" {
  rest_api_id          = var.api_id
  resource_id          = aws_api_gateway_resource.function_v1_proxy.id
  http_method          = "GET"
  authorization        = "NONE"
  api_key_required     = true
}

resource "aws_api_gateway_integration" "function_v1_proxy_get" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_method.function_v1_proxy_get.resource_id
  http_method             = aws_api_gateway_method.function_v1_proxy_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_method_response" "function_v1_proxy_get" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.function_v1_proxy.id
  http_method = aws_api_gateway_method.function_v1_proxy_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method" "function_v1_proxy_post" {
  rest_api_id          = var.api_id
  resource_id          = aws_api_gateway_resource.function_v1_proxy.id
  http_method          = "POST"
  authorization        = "NONE"
  api_key_required     = true
}

resource "aws_api_gateway_integration" "function_v1_proxy_post" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_method.function_v1_proxy_post.resource_id
  http_method             = aws_api_gateway_method.function_v1_proxy_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_method_response" "function_v1_proxy_post" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.function_v1_proxy.id
  http_method = aws_api_gateway_method.function_v1_proxy_post.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# -------------------------------------
# CORS
# -------------------------------------
resource "aws_api_gateway_method" "function_v1_proxy_option" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.function_v1_proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "function_v1_proxy_option" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.function_v1_proxy.id
  http_method = aws_api_gateway_method.function_v1_proxy_option.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "function_v1_proxy_option" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.function_v1_proxy.id
  http_method = aws_api_gateway_method.function_v1_proxy_option.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "function_v1_proxy_option" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.function_v1_proxy.id
  http_method = aws_api_gateway_method.function_v1_proxy_option.http_method
  status_code = aws_api_gateway_method_response.function_v1_proxy_option.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'content-type,accept,accept-encoding,authorization,x-api-key'",
    "method.response.header.Access-Control-Allow-Methods"     = "'GET,OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"      = "'*'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

# -------------------------------------
# Lambda Permissions
# -------------------------------------
resource "aws_lambda_permission" "function_v1" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*${aws_api_gateway_resource.function_v1.path}/*"
}
