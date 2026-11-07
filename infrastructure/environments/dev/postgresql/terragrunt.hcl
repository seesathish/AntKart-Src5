# =============================================================================
# Unit — PostgreSQL Flexible Server
# =============================================================================
# The system of record behind Orders and Users. One server, one database per
# service — separate schemas with separate connection strings, so no service can
# read another's tables even though they share a server. On a personal
# subscription one server is the affordable shape; the boundary is the database.
#
# COST WARNING: a stopped Flexible Server AUTO-STARTS after 7 days. Stopping it
# between sessions saves real money, but it will quietly come back on its own.
# That is what the env-stop/env-start pipelines exist to manage.
#
# THE DEVELOPER FIREWALL RULE IS OPTIONAL and reads a public IP from the
# AK_CLIENT_IP environment variable. An IP address is personal data and is never
# committed. Unset, no rule is created and the server is reachable only from
# Azure — which is all CI and the cluster need:
#
#     export AK_CLIENT_IP="$(curl -s https://api.ipify.org)"

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
  source = "../../../modules/postgresql"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name

  # The PAIRED region, not the resource group's — see data_location in root.hcl.
  location = include.root.locals.data_location

  server_name = include.root.locals.postgresql_name

  database_names = ["AKOrdersDb", "AKUsersDb"]

  allowed_client_ip = get_env("AK_CLIENT_IP", "")

  tags = include.root.locals.common_tags
}
