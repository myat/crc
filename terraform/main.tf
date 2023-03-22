provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      stack       = "crc-frontend"
      project     = "crc"
      environment = "staging"
    }
  }
}

# Module to iterate through the directory

module "template_files" {
  source   = "hashicorp/dir/template"
  version  = "~>1.0.2"
  base_dir = "../src"
}

# Create a S3 bucket and upload files

resource "random_pet" "frontend_bucket_name" {
  prefix = "crc-frontend-bucket"
  length = 3
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
    bucket          = "km-resume-crc-logs.s3.amazonaws.com"
    prefix          = "cf-logs-frontend-staging"
  }

  #aliases = ["mysite.example.com", "yoursite.example.com"]

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_control" "frontend_bucket_oac" {
  name                              = "frontend_bucket_oac"
  description                       = "OAC Policy to access the frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}