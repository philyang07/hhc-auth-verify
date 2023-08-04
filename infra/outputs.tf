output "api" {
  description = "Endpoint of the API"
  value       = "https://${aws_api_gateway_domain_name.function.domain_name}"
}

output "test_api_key" {
  description = "Test API key"
  value       = aws_api_gateway_api_key.test.value
  sensitive   = true
}
