# =============================================================================
# Unit — Resource Group
# =============================================================================
# A "unit" is the deployable instance of a module for this environment. The
# module says HOW to build the thing; this file says WHAT values to use here and
# inherits the backend/provider from the root.
#
# This is wave 0: every other unit depends on it, directly or transitively.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/resource-group"
}

inputs = {
  name     = include.root.locals.resource_group_name
  location = include.root.locals.location
  tags     = include.root.locals.common_tags
}
