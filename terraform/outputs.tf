# Output values

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store Lambda code"

  value = aws_s3_bucket.lambda_bucket.id
}

output "api_gw_url" {
  description = "URL of the API GW endpoint"

  value = aws_api_gateway_deployment.lambda_api_deployment.invoke_url
}

output "api_gw_regional_domain" {
  description = "Regional domain for API GW"

  value = aws_api_gateway_domain_name.api_gateway_custom_domain.regional_domain_name
}

output "api_gw_customain_domain" {
  description = "Custom domain for API GW"

  value = aws_api_gateway_domain_name.api_gateway_custom_domain.domain_name
}