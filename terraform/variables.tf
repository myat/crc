# Input variables

variable "aws_region" {
  description = "Default AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "deployment_env" {
  description = "The environment to deploy to. This has impact on domain names among others"
  type        = string
  default     = "STAGE"
  nullable    = false

  validation {
    condition     = contains(["STAGE", "PROD"], var.deployment_env)
    error_message = "Variable deployment_env must be one of: STAGE (default), PROD."
  }
}


variable "apex_domain" {
  description = "Primary domain name"
  type        = string
  default     = "kgmy.at"
}
