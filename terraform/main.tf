provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      stack       = "crc-backend"
      project     = "crc"
      environment = "staging"
    }
  }
}

provider "gandi" {
  key = data.aws_ssm_parameter.ssm_gandi_api_key.value
}

# Upload function archive to S3 

resource "random_pet" "lambda_bucket_name" {
  prefix = "crc-backend-lambda-function-bucket"
  length = 3
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

resource "aws_s3_object" "lambda_function_archive" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda_function.zip"
  source = data.archive_file.lambda_function.output_path
  etag   = filemd5(data.archive_file.lambda_function.output_path)
}

# Create a role for lambda, allow lambda to AssumeRole
# Attach AWSLambdaBasicExecutionRole policy to role

resource "aws_iam_role" "visitor_counter_lambda_role" {
  name = "visitor_counter_lambda_role"

  assume_role_policy = data.aws_iam_policy_document.allow_lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_dynamodb_rw_basic_exec" {
  name   = "allow_lambda_visitor_count_table_rw"
  policy = data.aws_iam_policy_document.combined_lambda_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_rw_role_policy_attachment" {
  role       = aws_iam_role.visitor_counter_lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_rw_basic_exec.arn
}


# Create the lambda function

resource "aws_lambda_function" "visitor_counter" {
  function_name = "VisitorCounterFunction"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_function_archive.key

  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  role = aws_iam_role.visitor_counter_lambda_role.arn
}

# Create DynamoDB table
resource "aws_dynamodb_table" "visitor_count_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "site_name"

  attribute {
    name = "site_name"
    type = "S"
  }
}


# Define the use of rest API
resource "aws_api_gateway_rest_api" "visitor_api" {
  name = "visitor_api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# The resource for the endpoint
resource "aws_api_gateway_resource" "lambda" {
  path_part   = "{proxy+}"
  parent_id   = aws_api_gateway_rest_api.visitor_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
}

# How the gateway will be interacted from clientt
resource "aws_api_gateway_method" "lambda" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integration between lambda and api gw
resource "aws_api_gateway_integration" "redirect" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id = aws_api_gateway_resource.lambda.id
  http_method = aws_api_gateway_method.lambda.http_method
  # Lambda invokes requires a POST method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitor_counter.invoke_arn
}

# Define lambda permissions to grant API gateway, source arn is not needed
resource "aws_lambda_permission" "allow_api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
}

# Activate deployment
resource "aws_api_gateway_deployment" "lambda_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.redirect
  ]

  rest_api_id = aws_api_gateway_rest_api.visitor_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# Set API stage name
resource "aws_api_gateway_stage" "lambda_api_deployment_stage" {
  deployment_id = aws_api_gateway_deployment.lambda_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.visitor_api.id
  stage_name    = var.infra_environment
}

# Set custom domain name for use with API gateway
resource "aws_api_gateway_domain_name" "api_gateway_custom_domain" {
  domain_name              = var.api_gateway_custom_domain
  regional_certificate_arn = aws_acm_certificate_validation.api_domain_cert_dns_validation.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Issue a certificate in ACM with DNS validation option

resource "aws_acm_certificate" "api_domain_cert" {
  domain_name       = var.api_gateway_custom_domain
  validation_method = "DNS"
}

# Add DNS validation record on Gandi

resource "gandi_livedns_record" "dns_validation_record" {
  zone = data.gandi_domain.apex_domain_zone.id

  # Gandi DNS records need to be without the apex domain
  name = replace(tolist(aws_acm_certificate.api_domain_cert.domain_validation_options)[0].resource_record_name, ".${var.apex_domain}.", "")

  type   = tolist(aws_acm_certificate.api_domain_cert.domain_validation_options)[0].resource_record_type
  ttl    = 300
  values = [tolist(aws_acm_certificate.api_domain_cert.domain_validation_options)[0].resource_record_value]
}

# Verify DNS validation records

resource "aws_acm_certificate_validation" "api_domain_cert_dns_validation" {
  certificate_arn = aws_acm_certificate.api_domain_cert.arn
  depends_on = [
    gandi_livedns_record.dns_validation_record,
  ]
}

# Map custom domain to API stage
resource "aws_api_gateway_base_path_mapping" "api_domain_mapping" {
  api_id      = aws_api_gateway_rest_api.visitor_api.id
  stage_name  = aws_api_gateway_stage.lambda_api_deployment_stage.stage_name
  domain_name = aws_api_gateway_domain_name.api_gateway_custom_domain.domain_name
}

# Add CNAME to API regional domain name on Gandi
resource "gandi_livedns_record" "cname_api_gateway" {
  zone   = data.gandi_domain.apex_domain_zone.id
  name   = replace(var.api_gateway_custom_domain, ".${var.apex_domain}", "")
  type   = "CNAME"
  ttl    = 300
  values = ["${aws_api_gateway_domain_name.api_gateway_custom_domain.regional_domain_name}."]
}

# Add CORS config
module "cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.visitor_api.id
  api_resource_id = aws_api_gateway_resource.lambda.id

  allow_methods = [
    "OPTIONS",
    "HEAD",
    "GET"
  ]
  allow_origin = "staging.kgmy.at"
}