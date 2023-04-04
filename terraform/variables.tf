# Input variables

variable "aws_region" {
  description = "Default AWS region for all resources"
  type        = string
  default     = "us-east-1"
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

# Path to get the site static files from
# These will be uploaded to S3
# Could be modified during PROD deployment (e.g. ../dist/)

variable "static_files_path" {
  description = "Path to static files to be hosted on S3"
  type        = string
  default     = "../src"
  nullable    = false
}


# Domain name to get the Gandi DNS zone

variable "apex_domain" {
  description = "Primary domain name"
  type        = string
  default     = "kgmy.at"
}
