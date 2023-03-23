# Output values

output "frontend_bucket_name" {
  description = "Name of the frontend files S3 bucket"

  value = aws_s3_bucket.frontend_bucket.id
}

output "cf_dist_id" {
  description = "ID of the CloudFront distribution"

  value = aws_cloudfront_distribution.frontend_distribution.id
}

output "cf_dist_domain_name" {
  description = "URL of the CloudFront distribution"

  value = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "acm_cert_time" {
  description = "Time at which the certificate was issued"

  value = aws_acm_certificate_validation.cert_dns_validatiion.id
}