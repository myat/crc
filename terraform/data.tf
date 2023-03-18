# All data sources used

data "archive_file" "lambda_function" {
  type = "zip"

  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/../lambda_function.zip"
}

data "aws_iam_policy_document" "allow_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "allow_lambda_dynamodb_rw" {
  statement {
    sid    = "AllowReadWrite"
    effect = "Allow"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:UpdateTimeToLive",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:UpdateTable",
      "dynamodb:GetRecords"
    ]

    resources = [
      "${aws_dynamodb_table.visitor_count_table.arn}",
      "${aws_dynamodb_table.visitor_count_table.arn}/index/*",
      "${aws_dynamodb_table.visitor_count_table.arn}/stream/*"
    ]
  }
}

data "aws_iam_policy_document" "lambda_basic_exec" {
  statement {
    sid    = "LambdaBasicExec"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "combined_lambda_role" {
  source_policy_documents = [
    data.aws_iam_policy_document.allow_lambda_dynamodb_rw.json,
    data.aws_iam_policy_document.lambda_basic_exec.json
  ]
}