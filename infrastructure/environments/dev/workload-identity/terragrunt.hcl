# =============================================================================
# Unit — Workload identity (one federated identity per service)
# =============================================================================
# This unit is where the secret-less model completes, and it is the single most
# important piece of infrastructure for D5. For each service it creates a
# user-assigned managed identity, federates it to the cluster's OIDC issuer for
# ONE Kubernetes ServiceAccount, and grants that identity only the data-plane
# roles the service actually needs.
#
# THE CHAIN, end to end:
#   the cluster projects a short-lived ServiceAccount token into the pod
#     -> the pod presents it to Entra
#       -> Entra matches issuer + subject against a federated credential
#         -> Entra returns a token for that service's managed identity
#           -> the identity's scoped data-plane roles decide what it can touch
# No credential is stored in the cluster, the repo, or a pipeline at any point.
#
# THE SUBJECT IS EXACT-MATCH AND CASE-SENSITIVE:
#   system:serviceaccount:<namespace>:<service_account_name>
# Rename a Kubernetes ServiceAccount — or the namespace — and workload identity
# breaks SILENTLY: the pod starts, and the first Azure call fails with an
# authentication error that says nothing about naming. The Helm chart's
# `name` value and the service_account_name below must stay in lockstep.
#
# WORKLOAD IDENTITY IS NOT THE SAME AS USER IDENTITY. Everything in this file is
# the SERVICE's identity, used to reach Azure resources. It is deliberately NOT
# how the platform decides what data a caller may see: that is the user's own
# token, propagated along every hop and re-validated by each service (D5). An
# agent that confused the two would be able to read any user's orders, which is
# exactly the failure the cross-user negative case demonstrates (D10).

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

dependency "aks" {
  config_path = "../aks"
  mock_outputs = {
    oidc_issuer_url = "https://eastus.oic.prod-aks.azure.com/00000000-0000-0000-0000-000000000000/11111111-1111-1111-1111-111111111111/"
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

dependency "key_vault" {
  config_path = "../key-vault"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${include.root.locals.resource_group_name}/providers/Microsoft.KeyVault/vaults/${include.root.locals.key_vault_name}"
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "../../../modules/workload-identity"
}

locals {
  # Every service reads its configuration secrets from the vault. "Secrets User"
  # reads secret VALUES and nothing else — it cannot create, change or delete a
  # secret. "Secrets Officer" could, and no service needs that.
  key_vault_read = {
    role_definition_name = "Key Vault Secrets User"
    scope                = dependency.key_vault.outputs.id
  }
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location

  oidc_issuer_url = dependency.aks.outputs.oidc_issuer_url
  namespace       = include.root.locals.k8s_namespace

  # ---------------------------------------------------------------------------
  # STILL TO ADD, once the ai-search and openai units exist:
  #
  #   catalogue    + "Search Index Data Reader"        on the AI Search service
  #   orchestrator + "Search Index Data Reader"        on the AI Search service
  #   orchestrator + "Cognitive Services OpenAI User"  on the OpenAI account
  #
  # Those two units are NOT in this repository yet — they are new modules, not
  # adapted ones, and the OpenAI module's model deployments depend on which
  # models the access request actually grants. Until then, every identity below
  # has vault read access only, which is enough to deploy and run the services
  # and to prove the identity chain itself.
  #
  # Note that NEITHER the catalogue nor the orchestrator gets a WRITE role on
  # the search index. Ingestion is a separate, deliberate operation run with its
  # own identity — an agent that could rewrite the index it retrieves from would
  # be able to plant its own grounding, which is the prompt-injection negative
  # case with extra steps.
  # ---------------------------------------------------------------------------
  services = {
    gateway = {
      service_account_name = "ak-gateway"
      role_assignments     = [local.key_vault_read]
    }
    users = {
      service_account_name = "ak-users"
      role_assignments     = [local.key_vault_read]
    }
    catalogue = {
      service_account_name = "ak-catalogue"
      role_assignments     = [local.key_vault_read]
    }
    cart = {
      service_account_name = "ak-cart"
      role_assignments     = [local.key_vault_read]
    }
    orders = {
      service_account_name = "ak-orders"
      role_assignments     = [local.key_vault_read]
    }
    # The .NET MCP server: the typed-tool boundary the agents call through (D2).
    mcp = {
      service_account_name = "ak-mcp"
      role_assignments     = [local.key_vault_read]
    }
    # The Python LangGraph supervisor and its four specialist agents (D1, D4).
    orchestrator = {
      service_account_name = "ak-orchestrator"
      role_assignments     = [local.key_vault_read]
    }
  }

  tags = include.root.locals.common_tags
}
