# Providers needed

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

provider "gandi" {
  key = data.aws_ssm_parameter.ssm_gandi_api_key.value
}

# Module to iterate through the directory

module "template_files" {
  source   = "hashicorp/dir/template"
  version  = "~>1.0.2"
  base_dir = var.static_files_path
}

# Create a S3 bucket and upload files

resource "random_pet" "frontend_bucket_name" {
  prefix = lower(format("%s-bucket-%s", local.project, var.deployment_env))
  length = 2
}

resource "random_pet" "cf_log_bucket_name" {
  prefix = lower(format("%s-log-bucket-%s", local.project, var.deployment_env))
  length = 2
}

resource "aws_s3_bucket" "cf_log_bucket" {
  bucket = random_pet.cf_log_bucket_name.id
}

resource "aws_s3_bucket_acl" "cf_log_bucket_acl" {
  bucket = aws_s3_bucket.cf_log_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = random_pet.frontend_bucket_name.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "private"
}

resource "aws_s3_object" "frontend_files" {
  for_each = module.template_files.files

  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  etag = each.value.digests.md5
}

# Allow CloudFront principal to access S3 bucket

resource "aws_s3_bucket_policy" "allow_cf_s3_read_only" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.allow_cf_s3_read_only.json
}

# CloudFront configuration

resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_bucket_oac.id
    origin_id                = aws_s3_bucket.frontend_bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution of frontend files from S3 backend"
  default_root_object = "index.html"
  #retain_on_delete    = true
  wait_for_deployment = false

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cf_log_bucket.bucket_domain_name
    prefix          = lower(format("cf-logs-%s-%s", local.project, var.deployment_env))
  }

  aliases = [local.cf_alias_domain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend_bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  # Use ACM issued certificate for alias domain
  # Remember to set ssl_support_method to sni-only

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.domain_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# OAC on CF distribution

resource "aws_cloudfront_origin_access_control" "frontend_bucket_oac" {
  name                              = "frontend_bucket_oac"
  description                       = "OAC Policy to access the frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Issue a certificate in ACM with DNS validation option

resource "aws_acm_certificate" "domain_cert" {
  domain_name       = local.cf_alias_domain
  validation_method = "DNS"
}

# Add DNS validation record on Gandi

resource "gandi_livedns_record" "dns_validation_record" {
  zone = data.gandi_domain.apex_domain_zone.id

  # Gandi DNS records need to be without the apex domain
  name = replace(tolist(aws_acm_certificate.domain_cert.domain_validation_options)[0].resource_record_name, ".${var.apex_domain}.", "")

  type   = tolist(aws_acm_certificate.domain_cert.domain_validation_options)[0].resource_record_type
  ttl    = 300
  values = [tolist(aws_acm_certificate.domain_cert.domain_validation_options)[0].resource_record_value]
}

# Verify DNS validation records

resource "aws_acm_certificate_validation" "cert_dns_validatiion" {
  certificate_arn = aws_acm_certificate.domain_cert.arn
  depends_on = [
    gandi_livedns_record.dns_validation_record,
  ]
}

# Add CNAME to CF distribution on Gandi

resource "gandi_livedns_record" "cname_frontend_cf_dist" {
  zone   = data.gandi_domain.apex_domain_zone.id
  name   = replace(local.cf_alias_domain, ".${var.apex_domain}", "")
  type   = "CNAME"
  ttl    = 300
  values = ["${aws_cloudfront_distribution.frontend_distribution.domain_name}."]
}