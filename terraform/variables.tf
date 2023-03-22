# Input variables

variable "aws_region" {
  description = "Default AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "cf_alias_domain" {
  description = "Custom domain name to serve as CloudFront alias"
  type        = string
  default     = "restaging.kgmy.at"
}