# =============================================================================
# Unit — Governance (monthly budget + cost alerts)
# =============================================================================
# This runs EARLY on purpose. Azure OpenAI, AI Search and an AKS cluster on a
# personal subscription can produce a surprising bill, and a budget's whole job
# is to remove the surprise. It does NOT cap or stop spending — it watches and
# emails as thresholds approach.
#
# THE ALERT ADDRESS IS NOT COMMITTED. An email address is personal data, and
# this repository is written to be published. It is read from the AK_ALERT_EMAIL
# environment variable, and get_env with no default means an unset variable
# FAILS the run rather than quietly creating a budget nobody is told about:
#
#     export AK_ALERT_EMAIL="you@example.com"

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${include.root.locals.resource_group_name}"
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "../../../modules/governance"
}

inputs = {
  resource_group_id = dependency.resource_group.outputs.id

  budget_name = "budget-${include.root.locals.name_prefix}"

  # USD per month. Sized for a platform that is STOPPED between sessions (see
  # the env-stop pipeline): AKS and PostgreSQL running continuously would exceed
  # this on their own. If the budget alerts in a quiet week, something was left
  # running — that is the signal, and it is the point.
  amount = 150

  # Must be the first of a month, and Azure rejects a start date far in the past.
  start_date = "2026-11-01T00:00:00Z"

  contact_emails = [get_env("AK_ALERT_EMAIL")]
}
