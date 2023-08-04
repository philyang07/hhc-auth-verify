# -------------------------------------
# Function
# -------------------------------------
module "function" {
  source = "./modules/function"

  name = local.full_name

  api_id               = aws_api_gateway_rest_api.api.id
  api_arn              = aws_api_gateway_rest_api.api.arn
  api_execution_arn    = aws_api_gateway_rest_api.api.execution_arn
  api_root_resource_id = aws_api_gateway_rest_api.api.root_resource_id

  debug = var.debug

  tags = local.common_tags
}

# -------------------------------------
# WAF
# -------------------------------------
resource "aws_wafv2_web_acl_association" "acl_association" {
  resource_arn = "${aws_api_gateway_rest_api.api.arn}/stages/api"
  web_acl_arn  = data.aws_ssm_parameter.waf_arn.value

  depends_on = [
    aws_api_gateway_deployment.api
  ]
}
