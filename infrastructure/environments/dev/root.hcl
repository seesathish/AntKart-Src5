# =============================================================================
# Terragrunt ROOT configuration — dev environment
# =============================================================================
# One place configures the Terraform remote state backend, the provider, and the
# provider versions for EVERY unit in this environment. Each unit includes this
# root, so none of them configures a backend itself and none of them can drift.
#
#     include "root" {
#       path   = find_in_parent_folders("root.hcl")
#       expose = true
#     }
#
# `expose = true` additionally makes the locals below readable from the unit as
# include.root.locals.<name>. That is what makes the PROJECT PREFIX real (D8):
# resource names are composed here, once, and every unit and every dependency
# mock reads them. Renaming the project, moving region, or standing up a second
# environment is an edit to the locals in this file — not a hunt through units.
#
# A SECOND ENVIRONMENT is a copy of this folder with `environment` below changed
# (and a matching state container created). Nothing else moves.

locals {
  # --- The parameterised identity of this environment ----------------------
  # project is a single lowercase alphanumeric token on purpose: Azure storage
  # accounts and container registries permit NO hyphens, so one token composes
  # cleanly into both the hyphenated names (rg-, kv-, aks-) and the compact ones
  # (acr…, st…). A hyphenated project would need two variables kept in sync.
  project     = "antkartai"
  environment = "dev"
  location    = "eastus"

  # PostgreSQL and Redis are provisioned in the PAIRED region. eastus is
  # offer-restricted for the Flexible Server SKU this platform uses, and that
  # restriction is account-specific, so this is the kind of value that has to be
  # discovered rather than assumed. Changing it here moves both data services.
  data_location = "eastus2"

  # --- Derived resource names ----------------------------------------------
  # Composed once; read by the units AND by their dependency mocks, so a mock
  # can never disagree with the name the unit actually creates.
  name_prefix = "${local.project}-${local.environment}"

  resource_group_name = "rg-${local.name_prefix}-${local.location}"
  vnet_name           = "vnet-${local.name_prefix}-${local.location}"
  acr_name            = "acr${local.project}${local.environment}"
  key_vault_name      = "kv-${local.name_prefix}"
  log_analytics_name  = "log-${local.name_prefix}"
  app_insights_name   = "appi-${local.name_prefix}"
  aks_name            = "aks-${local.name_prefix}"
  postgresql_name     = "psql-${local.name_prefix}-eus2"
  redis_name          = "redis-${local.name_prefix}"

  # The Kubernetes namespace every service runs in. This is load-bearing beyond
  # naming: the workload-identity federated credential subject is
  # system:serviceaccount:<namespace>:<serviceaccount>, matched EXACTLY and
  # case-sensitively by Entra. Change this and every federated credential, and
  # every Helm release, must change with it.
  k8s_namespace = "antkart"

  # --- Where the CI/CD federation trusts from ------------------------------
  github_org  = "seesathish"
  github_repo = "AntKart-Src5"

  common_tags = {
    environment = local.environment
    project     = local.project
    managed-by  = "terraform"
  }

  # --- Remote state coordinates --------------------------------------------
  # A dedicated resource group and storage account, deliberately SEPARATE from
  # the application resources so an environment teardown can never delete the
  # state that describes it. Storage account names are GLOBALLY unique and
  # limited to 3-24 lowercase alphanumerics; bootstrap these two by hand once
  # (see infrastructure/README.md) before the first terragrunt run.
  state_resource_group  = "rg-${local.project}-tfstate"
  state_storage_account = "st${local.project}tfstate"
  state_container       = "tfstate-${local.environment}"
}

remote_state {
  # The azurerm backend stores state as a blob and locks it with a blob LEASE,
  # so a second concurrent apply cannot acquire the lock and is refused —
  # operations serialise and state cannot be corrupted.
  backend = "azurerm"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    resource_group_name  = local.state_resource_group
    storage_account_name = local.state_storage_account
    container_name       = local.state_container

    # Each unit gets its OWN state blob, keyed by its path relative to this
    # root — so two units can never write to the same state file. This is the
    # isolation that lets one unit be destroyed and rebuilt on its own.
    key = "${path_relative_to_include()}/terraform.tfstate"

    # Authenticate to the state storage with the Entra identity from the ARM_*
    # environment variables rather than a storage account key. The state storage
    # account has shared-key access DISABLED, so Entra is the only path in; the
    # identity needs Storage Blob Data Contributor on it. No key in the repo.
    use_azuread_auth = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "azurerm" {
      features {}

      # Use the Entra identity (from ARM_*) for storage data-plane calls rather
      # than a storage account key.
      storage_use_azuread = true
    }
  EOF
}

# A single source of truth for provider versions, generated into every unit so
# they all resolve the SAME versions. Without this, two units — or the same unit
# on two different days — can pull different provider versions, and a plan that
# was clean yesterday changes for no code reason.
#
# azuread is used only by app-registration and github-oidc, and random only by
# postgresql (to generate the admin password), but all three are declared here so
# those units need no hand-written versions.tf of their own, which Terragrunt
# would then refuse to overwrite.
#
# After changing a constraint, run `terragrunt init -upgrade` in each unit to
# realign its .terraform.lock.hcl, then commit the updated lock files.
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 4.76"
        }
        azuread = {
          source  = "hashicorp/azuread"
          version = "~> 3.0"
        }
        random = {
          source  = "hashicorp/random"
          version = "~> 3.6"
        }
      }
    }
  EOF
}

# Passed down to every unit, so none of them repeats it.
inputs = {
  environment = local.environment
}
