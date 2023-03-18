# Input variables

variable "aws_region" {
  description = "Default AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_table_name" {
  description = "Name of visitor count DynamoDB table"
  type        = string
  default     = "visitor_count_table"
}