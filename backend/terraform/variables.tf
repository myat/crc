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

# Change this variable for PROD deployment
# Downstream locals: local.default_tags, local.cf_alias_domain

variable "deployment_env" {
  description = "The environment to deploy to. This has impact on domain names among others"
  type        = string
  default     = "stage"
  nullable    = false

  validation {
    condition     = contains(["stage", "prod"], var.deployment_env)
    error_message = "Variable deployment_env must be one of: stage (default), prod."
  }
}

# Domain name used to get the Gandi DNS zone 

variable "apex_domain" {
  description = "Primary domain name"
  type        = string
  default     = "kgmy.at"
}
