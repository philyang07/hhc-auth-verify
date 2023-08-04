# -------------------------------------
# Test API Key
# -------------------------------------
resource "aws_api_gateway_api_key" "test" {
  name        = "${local.full_name}-test"
  description = "API key used for testing"
  enabled     = true

  tags = merge(local.common_tags, { "Name" = "${local.full_name}-test" })
}

resource "aws_api_gateway_usage_plan_key" "test" {
  key_id        = aws_api_gateway_api_key.test.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api.id
}

# -------------------------------------
# User Portal API Key
# -------------------------------------
resource "aws_api_gateway_api_key" "user_portal" {
  name        = "${local.full_name}-user-portal"
  description = "API key used for user portal"
  enabled     = true

  tags = merge(local.common_tags, { "Name" = "${local.full_name}-user-portal" })
}

resource "aws_api_gateway_usage_plan_key" "user_portal" {
  key_id        = aws_api_gateway_api_key.user_portal.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api.id
}

# -------------------------------------
# Route53 Subdomain
# -------------------------------------
resource "aws_route53_record" "function" {
  name    = aws_api_gateway_domain_name.function.domain_name
  zone_id = data.aws_route53_zone.public.zone_id
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.function.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.function.regional_zone_id
    evaluate_target_health = true
  }
}

# -------------------------------------
# API Domain
# -------------------------------------
resource "aws_api_gateway_domain_name" "function" {
  domain_name              = "${var.sub_domain != "" ? var.sub_domain : local.full_name}.${data.aws_route53_zone.public.name}"
  regional_certificate_arn = data.aws_ssm_parameter.cert_arn.value
  endpoint_configuration {
    types = [
      "REGIONAL"
    ]
  }

  tags = local.common_tags
}

resource "aws_api_gateway_base_path_mapping" "function" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = aws_api_gateway_domain_name.function.domain_name
}

# -------------------------------------
# API
# -------------------------------------
resource "aws_api_gateway_rest_api" "api" {
  name = local.full_name

  api_key_source = "HEADER"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*",
      "Principal": "*"
    }
  ]
}
POLICY

  tags = merge(local.common_tags, { "Name" = local.full_name })
}

# -------------------------------------
# API Deployment
# -------------------------------------
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.function
  ]
}

# -------------------------------------
# API Stage
# -------------------------------------
resource "aws_api_gateway_stage" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = "api"

  depends_on = [aws_cloudwatch_log_group.api]

  tags = merge(local.common_tags, { "Name" = local.full_name })
}

resource "aws_api_gateway_method_settings" "logs" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/api"
  retention_in_days = 7

  tags = local.common_tags
}

# -------------------------------------
# API Usage Plan
# -------------------------------------
resource "aws_api_gateway_usage_plan" "api" {
  name        = local.full_name
  description = "Usage plan for ${local.full_name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.api.stage_name
  }

  quota_settings {
    limit  = 1000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 10
    rate_limit  = 10
  }

  tags = merge(local.common_tags, { "Name" = local.full_name })
}

# -------------------------------------
# API Error Alarms
# -------------------------------------
resource "aws_cloudwatch_metric_alarm" "errors_4xx" {
  alarm_name          = "${local.full_name}-errors-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.api.name
    Stage   = aws_api_gateway_stage.api.stage_name
  }

  alarm_description = "Monitors API Errors"
  alarm_actions     = [data.aws_sns_topic.alert.arn]

  tags = merge(local.common_tags, { "Name" = "${local.full_name}-errors-4xx" })
}

resource "aws_cloudwatch_metric_alarm" "errors_5xx" {
  alarm_name          = "${local.full_name}-errors-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXerror"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.api.name
    Stage   = aws_api_gateway_stage.api.stage_name
  }

  alarm_description = "Monitors API Errors"
  alarm_actions     = [data.aws_sns_topic.alert.arn]

  tags = merge(local.common_tags, { "Name" = "${local.full_name}-errors-5xx" })
}
