# Output values

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store Lambda code"

  value = aws_s3_bucket.lambda_bucket.id
}

output "api_gw_url" {
  value = aws_api_gateway_deployment.lambda_api_deployment.invoke_url
}