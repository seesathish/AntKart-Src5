# =============================================================================
# Unit — Networking (virtual network + subnets)
# =============================================================================
# One /16 split into purpose-named subnets. The aks subnet is sized /22 (1,022
# usable addresses) because with Azure CNI every POD takes an address from the
# subnet, not just every node — a /24 runs out as soon as the cluster scales.

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
  source = "../../../modules/networking"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location

  vnet_name          = include.root.locals.vnet_name
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    "aks" = {
      address_prefixes       = ["10.0.0.0/22"]
      allow_internet_ingress = true
    }
    # Reserved for private endpoints onto PostgreSQL, Key Vault, AI Search and
    # Azure OpenAI. Network policies must be Disabled on a subnet that hosts
    # private endpoints — Azure requires it.
    "private-endpoints" = {
      address_prefixes                  = ["10.0.4.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
    "gateway" = {
      address_prefixes = ["10.0.5.0/27"]
    }
  }

  tags = include.root.locals.common_tags
}
