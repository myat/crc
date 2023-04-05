locals {
  project = "crc-backend"
  # Default tags to be assigned to all resources
  default_tags = {
    project     = local.project
    stack       = format("%s-%s", local.project, var.deployment_env)
    environment = var.deployment_env
  }
}

locals {
  api_gateway_custom_domain = var.deployment_env == "prod" ? "api.kgmy.at" : "stagingapi.kgmy.at"
}