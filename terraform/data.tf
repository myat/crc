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

data "aws_ssm_parameter" "ssm_gandi_api_key" {
  name            = "/CRC/API/GandiDNS"
  with_decryption = true
}