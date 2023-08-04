#------------------------------------------
# Exported Data
#------------------------------------------

resource "aws_ssm_parameter" "api_endpoint" {

  name        = "/api/${local.full_name}/endpoint"
  description = "Exported API endpoint"
  type        = "String"
  value       = aws_api_gateway_domain_name.function.domain_name
  overwrite   = true

  tags = merge(local.common_tags, { "Name" = "/api/${local.full_name}/endpoint" })
}

resource "aws_ssm_parameter" "api_user_portal_key" {

  name        = "/api/${local.full_name}/user-portal-key"
  description = "Exported API key for User Portal integration"
  type        = "SecureString"
  value       = aws_api_gateway_api_key.user_portal.value
  overwrite   = true

  tags = merge(local.common_tags, { "Name" = "/api/${local.full_name}/user-portal-key" })
}
