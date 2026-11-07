# =============================================================================
# Unit — Observability (Log Analytics + Application Insights)
# =============================================================================
# ONE workspace is the whole design. Application Insights is created as
# WORKSPACE-BASED, so traces land in the same workspace as container logs, and a
# single KQL query can join a log line to the span it belongs to (a log's TraceId
# equals a span's OperationId). That join is what makes P4-2 — one trace across
# the Python orchestrator and the .NET services — answerable at all.
#
# This unit runs BEFORE key-vault, which stores the connection string it emits.

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
  source = "../../../modules/observability"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location

  log_analytics_name = include.root.locals.log_analytics_name
  app_insights_name  = include.root.locals.app_insights_name

  # Ingestion is the cost driver, not retention; 30 days is the free floor and
  # is more history than a reference platform needs.
  retention_days = 30

  tags = include.root.locals.common_tags
}
