locals {
  project = "CRC-FRONTEND"
  # Default tags to be assigned to all resources
  default_tags = {
    project     = local.project
    stack       = format("%s-%s", local.project, var.deployment_env)
    environment = var.deployment_env
  }
}

locals {
  cf_alias_domain = var.deployment_env == "PROD" ? "resume.kgmy.at" : "staging.kgmy.at"
}