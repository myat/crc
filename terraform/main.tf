provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      app = "crc-backend"
    }
  }
}

data "archive_file" "lambda_function" {
  type = "zip"

  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/../lambda_function.zip"
}

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