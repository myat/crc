# Create S3 read-only (bucket limited) policy for CF

data "aws_iam_policy_document" "allow_cf_s3_read_only" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.frontend_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.frontend_distribution.arn}"]
    }
  }
}

# Fetch Gandi API key

data "aws_ssm_parameter" "ssm_gandi_api_key" {
  name            = "/CRC/API/GandiDNS"
  with_decryption = true
}

# Fetch apex domain's zone data from Gandi

data "gandi_domain" "apex_domain_zone" {
  name = var.apex_domain
}