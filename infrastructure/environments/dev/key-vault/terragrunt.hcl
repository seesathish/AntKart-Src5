# =============================================================================
# Unit — Key Vault
# =============================================================================
# Holds every connection string and API key the platform needs at runtime. Two
# properties matter more than the vault itself:
#
#   * Nothing in the cluster stores a vault credential. A pod reads secrets with
#     its workload identity (the workload-identity unit grants Key Vault Secrets
#     User — read values, NOT manage them).
#   * The vault's DATA plane is a separate permission plane from Azure RBAC. An
#     Owner on the subscription is not thereby able to read a secret. That
#     surprises people, and it is the second of the four planes.
#
# It depends on observability because the App Insights connection string is
# stored here rather than injected as plain configuration.

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

dependency "observability" {
  config_path = "../observability"
  mock_outputs = {
    connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://eastus-0.in.applicationinsights.azure.com/"
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "../../../modules/key-vault"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location

  key_vault_name = include.root.locals.key_vault_name

  # FALSE deliberately, and it is a ONE-WAY switch — Azure will not let it be
  # disabled once enabled on a vault. This environment is meant to be destroyed
  # and rebuilt (that is the point of the lifecycle pipelines), and purge
  # protection would force every teardown to wait out the full soft-delete
  # retention before the name could be reused. A production vault sets this true.
  purge_protection_enabled = false

  app_insights_connection_string = dependency.observability.outputs.connection_string

  tags = include.root.locals.common_tags
}
