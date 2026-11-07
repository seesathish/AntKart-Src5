# Kubernetes delivery

Everything that runs in the cluster, and how it gets there. Adapted from the earlier AntKart
platform repository, with two deliberate changes noted below.

```
deploy/
├── helm/
│   ├── antkart-service/     ONE generic chart, instantiated once per workload
│   └── values/              Per-workload inputs (7 files)
├── argocd/
│   ├── appproject-antkart.yaml        Least-privilege project — APPLY FIRST
│   └── applicationset-antkart.yaml    The seven Applications, from one template
└── cert-manager/
    ├── cluster-issuer-staging.yaml    Start here
    └── cluster-issuer-prod.yaml       Switch once staging issues cleanly
```

## One chart, two runtimes

The five .NET services, the .NET MCP server and the **Python** orchestrator are all deployed by
the same chart. It knows nothing about what language is inside a container — the whole contract is
*listen on `containerPort`, serve `/health/live` and `/health/ready`*.

That is the point worth taking from this directory. Adopting multi-agent orchestration in a .NET
estate does not mean standing up a parallel Python platform beside it. The orchestrator is one
more Deployment, with the same identity wiring, the same probes, the same config mechanism and the
same delivery pipeline as everything else.

| Workload | Runtime | Exposed | Role |
|---|---|---|---|
| `ak-gateway` | .NET | **Ingress** | Validates the caller's token; routes |
| `ak-users` | .NET | ClusterIP | Profile, and the ownership checks |
| `ak-catalogue` | .NET | ClusterIP | Products, and product retrieval |
| `ak-cart` | .NET | ClusterIP | Cart — the agent's reversible writes |
| `ak-orders` | .NET | ClusterIP | Order history; the HITL gate |
| `ak-mcp` | .NET | ClusterIP | Typed-tool boundary (D2) |
| `ak-orchestrator` | Python | ClusterIP | Supervisor + four specialist agents (D1, D4) |

The orchestrator has **no ingress**, and that is a security decision rather than an oversight. An
agent loop reachable from the internet without passing the gateway's token validation would be an
unauthenticated path into every tool the agents can call.

## Two changes from the earlier platform

**One delivery path, not two.** The earlier repository carried both an ApplicationSet and a
parallel set of standalone Application manifests, as a teaching contrast. Both create the same
Application names, so applying one after the other silently reverted the other's parameters. Only
the ApplicationSet survives here.

**Config changes now actually roll the pods.** A ConfigMap change does *not* restart the pods that
consume it: Kubernetes updates the ConfigMap and the Deployment's own spec is untouched, so there
is nothing to roll. Argo CD reports the Application as **Synced** while every pod still holds the
old configuration. The chart now hashes its rendered ConfigMaps into a pod annotation, so a config
change changes the pod template and triggers a rolling update.

## Three values are empty in Git

Each fails loudly rather than deploying something that starts cleanly and then misbehaves.

| Value | Where | Source |
|---|---|---|
| `workloadIdentityClientId` | ApplicationSet, per element | `terragrunt output -json identities` in `infrastructure/environments/dev/workload-identity` — take each entry's `client_id` |
| `Entra__TenantId` / `__Audience` / `__ClientId` | ApplicationSet template parameters | `terragrunt output` in `infrastructure/environments/dev/app-registration` |
| `email` | both ClusterIssuers | Yours — Let's Encrypt sends expiry notices there |

They are empty because they identify a specific Entra directory. Anyone adopting this repository
has their own, so a committed value would be both a leak and wrong for them.

A missing `workloadIdentityClientId` is worth understanding, because the failure it prevents is a
nasty one. Without it the pod starts fine and then cannot authenticate to Azure, presenting as an
opaque credential error that says nothing about naming. The chart's `required` turns that into a
render-time failure instead.

## Order of operations

```bash
# 1. The namespace, and the controllers the chart depends on
kubectl create namespace antkart
# install ingress-nginx and cert-manager (see the provisioning notes)

# 2. The ClusterIssuer — staging first
kubectl apply -f deploy/cert-manager/cluster-issuer-staging.yaml

# 3. Argo CD's project, BEFORE anything that references it by name
kubectl apply -f deploy/argocd/appproject-antkart.yaml

# 4. The Applications
kubectl apply -f deploy/argocd/applicationset-antkart.yaml
```

**Argo CD does not watch its own ApplicationSet.** It reconciles the Applications the set
generates, but not the set itself — so an edit to `applicationset-antkart.yaml` has to be applied
with `kubectl` again. Changing an element and waiting for a sync that never comes is the second
most convincing wrong-but-green state in GitOps, after the ConfigMap problem above.

## Self-heal means Git is the only way in

`selfHeal: true` is on, so a `helm upgrade` or a `kubectl edit` against these workloads is
reverted. That is intended. `prune` is deliberately **off**: pruning deletes resources removed
from Git, which is the only destructive automation here, so a stray Git deletion cannot cascade
into the cluster.

## Rendering the chart locally

Values that are empty in Git have to be supplied, or `required` stops the render:

```bash
helm template ak-catalogue deploy/helm/antkart-service \
  -f deploy/helm/values/catalogue.yaml \
  --set workloadIdentityClientId=00000000-0000-0000-0000-000000000000
```
