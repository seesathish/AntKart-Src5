# =============================================================================
# Unit — Container Registry
# =============================================================================
# Holds the images for the five .NET services, the .NET MCP server and the
# Python orchestrator. Nothing authenticates to it with a password: CI pushes
# with AcrPush via GitHub OIDC federation (see the github-oidc unit) and the
# AKS kubelet identity pulls with AcrPull (granted by the aks unit).

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name     = include.root.locals.resource_group_name
    location = include.root.locals.location
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "../../../modules/container-registry"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location

  acr_name = include.root.locals.acr_name
  sku      = "Basic"

  tags = include.root.locals.common_tags
}
