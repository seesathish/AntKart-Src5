# =============================================================================
# Unit — GitHub OIDC federation (secret-less CI/CD)
# =============================================================================
# Creates the identity GitHub Actions assumes, and federates it to THIS
# repository so no Azure credential is ever stored in GitHub. A workflow run
# presents GitHub's own OIDC token; Entra matches its issuer and subject against
# a federated credential and returns a token for this identity.
#
# The subject claims below are the security boundary, and they are exact-match:
# only a run on the named branch, or in the named GitHub environment, can
# authenticate. A pull request from a fork cannot — which is the whole reason
# the CI workflows build and scan but never touch Azure, and only the CD
# workflows (push to main) log in.

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

dependency "container_registry" {
  config_path = "../container-registry"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${include.root.locals.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${include.root.locals.acr_name}"
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "../../../modules/github-oidc"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location

  github_org  = include.root.locals.github_org
  github_repo = include.root.locals.github_repo

  subjects = [
    { name = "main", claim = "ref:refs/heads/main" },
    { name = "env-${include.root.locals.environment}", claim = "environment:${include.root.locals.environment}" },
  ]

  # AcrPush only — CI/CD pushes images and does nothing else to the registry.
  acr_id = dependency.container_registry.outputs.id

  tags = include.root.locals.common_tags
}
