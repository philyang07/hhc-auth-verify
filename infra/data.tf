data "aws_region" "current" {}

#------------------------------------------
# Network
#------------------------------------------
data "aws_route53_zone" "public" {
  zone_id = data.aws_ssm_parameter.public_hosted_zone_id.value
}

data "aws_ssm_parameter" "public_hosted_zone_id" {
  name = "/infra/public-zone-id"
}

data "aws_ssm_parameter" "alert_topic" {
  name = "/infra/alert-topic"
}

data "aws_sns_topic" "alert" {
  name = data.aws_ssm_parameter.alert_topic.value
}

data "aws_ssm_parameter" "waf_arn" {
  name = "/infra/waf-arn"
}

data "aws_ssm_parameter" "cert_arn" {
  name = "/infra/wildcart-cert-arn"
}

