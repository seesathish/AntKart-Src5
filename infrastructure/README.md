# Infrastructure

Infrastructure-as-Code for the platform's cloud environment, provisioned with **Terraform** and
**Terragrunt**. Adapted from the earlier AntKart platform repository and re-parameterised, so the
modules are proven rather than new — but the environment is a fresh one.

## Layout — modules vs. environments

```
infrastructure/
├── modules/            Reusable Terraform modules — one per resource type (HOW)
└── environments/
    └── dev/            Terragrunt "live" units — one per deployed thing (WHAT)
        ├── root.hcl    Backend, provider, versions, and the project prefix
        └── <unit>/terragrunt.hcl
```

A **module** describes *how* a resource is built: it takes inputs, exposes outputs, and has no
environment-specific value baked in. A **unit** is one deployed instance of a module: it supplies
this environment's inputs and inherits the backend from the root.

Twelve modules: `resource-group`, `governance`, `networking`, `container-registry`, `key-vault`,
`observability`, `postgresql`, `redis`, `app-registration`, `workload-identity`, `github-oidc`,
`aks`.

Two more are still to be written — `ai-search` and `openai`. They are genuinely new, not adapted,
and the OpenAI module's model deployments depend on which models the access request grants.

## The project prefix

Every resource name is composed in `environments/dev/root.hcl` from a single `project` local, and
units read those names back through `include.root.locals`. Renaming the project, changing region,
or standing up a second environment is an edit to that one file — not a hunt through units.

A second environment is a copy of `environments/dev/` with `environment` changed in its `root.hcl`,
plus a matching state container.

## Two values are never committed

Both are personal data, and this repository is written to be published.

| Variable | Used by | If unset |
|---|---|---|
| `AK_ALERT_EMAIL` | `governance` — who the budget alerts | **The run fails.** A budget nobody is told about is not a budget. |
| `AK_CLIENT_IP` | `postgresql` — a developer machine allowed through the firewall | No developer rule is created. The server stays reachable from Azure, which is all CI and the cluster need. |

```bash
export AK_ALERT_EMAIL="you@example.com"
export AK_CLIENT_IP="$(curl -s https://api.ipify.org)"
```

## Before the first Terraform run

Two things must exist first, created with the Azure CLI, because Terraform cannot bootstrap the
state it stores itself in:

1. **A service principal** with Contributor and Role Based Access Control Administrator on the
   subscription, exported as the `ARM_*` environment variables.
2. **The remote-state resource group, storage account and container** named in `root.hcl`
   (`rg-antkartai-tfstate` / `stantkartaitfstate` / `tfstate-dev`), with shared-key access
   disabled and the service principal granted Storage Blob Data Contributor on it.

## Running a unit

```bash
cd infrastructure/environments/dev/<unit>
terragrunt init     # wire the backend, download providers, resolve dependencies
terragrunt plan     # read-only preview
terragrunt apply    # after reading the plan
```

`plan` before `apply`, every time. `terragrunt run-all <command>` from `environments/dev` acts on
every unit and respects the dependency order below.

## Dependency order

Units declare their own dependencies, so Terragrunt derives this — it is written out here only so
the shape is visible at a glance.

```
resource-group
├── governance              (budget — run it early)
├── networking
├── container-registry
├── observability
│   └── key-vault           (stores the App Insights connection string)
├── postgresql
├── redis
├── github-oidc             (also needs container-registry)
└── aks                     (also needs networking, container-registry, observability)
    └── workload-identity   (also needs key-vault; needs the cluster's OIDC issuer)

app-registration            (no dependency — a directory object, not an Azure resource)
```

`app-registration` standing outside the tree is not an oversight. An Entra app registration lives
in the **tenant**, not in a subscription, and that is the first of the four separate permission
planes this platform crosses. The others: Azure RBAC on resources, the Key Vault **data** plane,
and Kubernetes' own authorization inside the cluster. Holding a role on one grants nothing on
another, and that is the single most common source of "but I'm the owner" confusion.

## Cost

The budget in the `governance` unit alerts; it does not cap. AKS and PostgreSQL left running are
the two largest line items, which is why the environment is designed to be **stopped between
sessions**. Note that a stopped PostgreSQL Flexible Server **auto-starts after 7 days** — it will
come back on its own whether or not you are ready for it.
