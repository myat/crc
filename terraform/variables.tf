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

variable "api_gateway_custom_domain" {
  description = "Custom domain name to serve as CloudFront alias"
  type        = string
  default     = "stagingapi.kgmy.at"
}

variable "apex_domain" {
  description = "Primary domain name"
  type        = string
  default     = "kgmy.at"
}

variable "infra_environment" {
  description = "Environment and stage name to be used for deployment"
  type        = string
  default     = "staging"
}
