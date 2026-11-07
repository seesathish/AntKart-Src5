# =============================================================================
# Unit — AKS cluster
# =============================================================================
# The cluster that runs both runtimes: the .NET services and MCP server, and the
# Python orchestrator. They are ordinary Deployments next to each other — the
# polyglot boundary is an HTTP call, not a platform split.
#
# Two cluster settings are load-bearing beyond the cluster:
#   * The OIDC ISSUER is what workload identity federates to. Its URL is an
#     output of this unit and an input to workload-identity, which is why that
#     unit cannot run until this one exists.
#   * KUBERNETES AUTHORIZATION is the fourth separate permission plane. Azure
#     RBAC on the cluster resource governs who may FETCH credentials; what they
#     may then do inside the cluster is Kubernetes' own decision.

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

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    subnet_ids = {
      "aks"               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${include.root.locals.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${include.root.locals.vnet_name}/subnets/aks"
      "private-endpoints" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${include.root.locals.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${include.root.locals.vnet_name}/subnets/private-endpoints"
      "gateway"           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${include.root.locals.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${include.root.locals.vnet_name}/subnets/gateway"
    }
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

dependency "observability" {
  config_path = "../observability"
  mock_outputs = {
    workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${include.root.locals.resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/${include.root.locals.log_analytics_name}"
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "../../../modules/aks"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location

  cluster_name = include.root.locals.aks_name
  subnet_id    = dependency.networking.outputs.subnet_ids["aks"]

  # Grants the cluster's KUBELET identity AcrPull — a different identity from
  # the per-service workload identities, created with the cluster.
  acr_id = dependency.container_registry.outputs.id

  # Container Insights ships container stdout to the shared workspace.
  log_analytics_workspace_id = dependency.observability.outputs.workspace_id

  # Free tier: no uptime SLA on the control plane, no charge for it either. The
  # right trade for a reference environment that is stopped between sessions.
  sku_tier = "Free"

  # Two D2s_v3 nodes (2 vCPU / 8 GiB each) hold the .NET services, the MCP
  # server and the Python orchestrator at one replica apiece with headroom.
  node_vm_size = "Standard_D2s_v3"
  node_count   = 2

  # Local (certificate) admin access stays enabled so `az aks get-credentials`
  # works without first wiring Entra cluster admins. Disabling it is the
  # hardening step, and it belongs with the Kubernetes-authorization plane.
  local_account_disabled = false

  kubernetes_version = "1.35"

  tags = include.root.locals.common_tags
}
