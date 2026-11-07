# =============================================================================
# Unit — Redis
# =============================================================================
# Backs the Cart service. A cart is the natural home for the agent's REVERSIBLE
# writes (D6): the Cart agent may add and remove freely without a human gate,
# precisely because nothing it does there is irreversible. Keyed per user with a
# TTL, so an abandoned cart expires rather than accumulating.

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
  source = "../../../modules/redis"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = include.root.locals.data_location

  name = include.root.locals.redis_name

  tags = include.root.locals.common_tags
}
