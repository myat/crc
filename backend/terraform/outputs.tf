# Output values

output "api_gw_url" {
  description = "URL of the API GW endpoint"

  value = aws_api_gateway_deployment.lambda_api_deployment.invoke_url
}

output "api_gw_regional_domain" {
  description = "Regional domain for API GW"

  value = aws_api_gateway_domain_name.api_gateway_custom_domain.regional_domain_name
}

output "api_gw_custom_domain" {
  description = "Custom domain for API GW"

  value = aws_api_gateway_domain_name.api_gateway_custom_domain.domain_name
}