# Output values

output "cf_dist_id" {
  description = "ID of the CloudFront distribution"

  value = aws_cloudfront_distribution.frontend_distribution.id
}

output "cf_dist_domain_name" {
  description = "CloudFront distribution domain"

  value = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "cf_alias_domain" {
  description = "CF alias domain"

  value = tolist(aws_cloudfront_distribution.frontend_distribution.aliases)[0]
}

output "acm_cert_time" {
  description = "Time at which the certificate was issued"

  value = aws_acm_certificate_validation.cert_dns_validatiion.id
}