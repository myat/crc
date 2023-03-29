provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      stack = "crc-backend"
      project = "crc"
      environment = "staging"
    }
  }
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

# Create a bootstrap record
resource "aws_dynamodb_table_item" "visitor_counter_table_bootstrap_item" {
  table_name = aws_dynamodb_table.visitor_count_table.name
  hash_key   = aws_dynamodb_table.visitor_count_table.hash_key
  item       = local.bootstrap_json
}


# Define the use of rest API
resource "aws_api_gateway_rest_api" "visitor_api" {
  name = "visitor_api"
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
  stage_name  = "test"
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