# Backlog

Every work item, coarse enough to stay maintained. Each item is roughly a half-day to
two-day chunk. One item is **in progress** at a time; update status at the **end** of a
session, not during.

**Status convention:** 🔴 Not started · 🟡 In progress · 🟢 Done · ⏸️ Blocked (say what by)

Everything starts 🔴. Decisions referenced as **D1–D10** live in
[DECISIONS.md](DECISIONS.md).

---

## Phase 0 · Prerequisites (week 1)

| ID | Item | Detail | Status | Blocked by |
|----|------|--------|:------:|------------|
| P0-1 | Azure OpenAI access request | Gates all agent work — **submit immediately**; approval is the long pole | 🔴 | — |
| P0-2 | Service principal, four permission planes | Azure RBAC, Entra directory, Key Vault data plane, Kubernetes authorization | 🔴 | — |
| P0-3 | Repo skeleton and solution structure | Solution, `nuget.config`, ignore files, `CLAUDE.md`, READMEs — **done**. Service folders themselves not created (they arrive with P1-4) | 🟡 | — |
| P0-4 | Terraform + Terragrunt adapted | 12 modules + 12 units, parameterised by project prefix in `root.hcl` (D8). `role-assignments` dropped — Function-App-specific. **Not yet run against Azure** | 🟢 | — |
| P0-5 | Budget alert on the resource group | Cost discipline is real — personal Azure account. The `governance` unit exists; it has not been applied | 🔴 | — |
| P0-6 | `ai-search` Terraform module | **New, not adapted.** Check the FREE tier first — 50 MB and 3 indexes may be enough for two small corpora, against ~$75/month for Basic | 🔴 | — |
| P0-7 | `openai` Terraform module | **New, not adapted.** The `deployments` map depends on which models P0-1 actually grants | 🔴 | P0-1 |
| P0-8 | Decide the public/internal split for this repo | `docs/_internal/` is **tracked**, so the `.gitignore` entry does nothing — the planning files are in the repo's history. Either make Src5 private or move them out | 🔴 | — |

## Phase 1 · Platform (weeks 1–3)

| ID | Item | Detail | Status | Blocked by |
|----|------|--------|:------:|------------|
| P1-1 | Lifecycle workflows | `infra-up`, `infra-down`, `infra-plan`, `env-stop`, `env-start` (D8). **New** — the earlier repo had no such pipelines, it was run by hand | 🔴 | P0-4 |
| P1-2 | Core Azure resources | Provisioned and verified from the pipelines | 🔴 | P1-1 |
| P1-3 | AKS, Argo CD, ingress, cert-manager | Cluster and GitOps delivery baseline | 🔴 | P1-2 |
| P1-4 | Five .NET services deployed | Gateway, Users, Catalogue, Cart, Orders — deployed and healthy (D3). Helm values, Argo CD elements and CI/CD callers already exist and are dormant | 🔴 | P1-3 |
| P1-6 | Orchestrator Python skeleton | `orchestrator/` — `pyproject`, `requirements-dev.txt`, ruff/mypy config, the three health endpoints. Its CI workflow references this folder and is dormant until it exists | 🔴 | — |
| P1-5 | Identity | Entra app registration, workload identity, token validation at the gateway and re-validated per service | 🔴 | P1-4 |

## Phase 2 · Retrieval (weeks 4–5)

| ID | Item | Detail | Status | Blocked by |
|----|------|--------|:------:|------------|
| P2-1 | Document ingestion and chunking | The ingest pipeline — split with overlap | 🔴 | — |
| P2-2 | Embeddings and vector store | Azure AI Search as the retrieval layer | 🔴 | P2-1 |
| P2-3 | Retrieval with identity filtering | **A naive vector store leaks across users** — filter at retrieval by caller identity (D5) | 🔴 | P2-2, P1-5 |
| P2-4 | Two corpora | Product specifications, and policy documents | 🔴 | P2-2 |

## Phase 3 · Orchestration (weeks 6–7)

| ID | Item | Detail | Status | Blocked by |
|----|------|--------|:------:|------------|
| P3-1 | MCP server in .NET | Exposes typed tools over the existing services — the runtime boundary (D2) | 🔴 | P1-4 |
| P3-2 | Python orchestrator skeleton | LangGraph scaffold | 🔴 | — |
| P3-3 | Supervisor and routing | The routing node (D1) | 🔴 | P3-2 |
| P3-4 | Four specialist agents | Catalogue, Cart, Orders, Support (D4) | 🔴 | P3-3, P3-1 |
| P3-5 | Identity propagation end to end | User token: gateway → orchestrator → MCP → service (D5) | 🔴 | P3-4, P1-5 |
| P3-6 | HITL gate on order placement | Agent proposes a structured order; nothing commits until approved (D6) | 🔴 | P3-4 |
| P3-7 | Bounded autonomy | Step cap, token budget, recursion guard on handoffs, idempotent tools (D7) | 🔴 | P3-3 |

## Phase 4 · Enterprise hardening (week 8)

| ID | Item | Detail | Status | Blocked by |
|----|------|--------|:------:|------------|
| P4-1 | Four negative cases | Prompt injection via retrieved content, cross-user access attempt, runaway tool loop, hallucinated action rejected by schema validation (D10) | 🔴 | P3-5, P3-7 |
| P4-2 | Observability | **One trace** spanning the Python orchestrator and the .NET services | 🔴 | P3-5 |
| P4-3 | Evaluation | Golden dataset; regression check when the model version changes | 🔴 | P3-4 |
| P4-4 | Cost | Token telemetry, caching, budget alerting | 🔴 | P4-2 |

## Phase 5 · Documentation (week 9)

| ID | Item | Detail | Status | Blocked by |
|----|------|--------|:------:|------------|
| P5-1 | README + getting-started | With the **cost warning** and the one-time setup | 🔴 | — |
| P5-2 | Diagrams | C4 diagrams, agent loop diagram, sequence flow per use case, the identity chain | 🔴 | — |
| P5-3 | ADRs | Derived from [DECISIONS.md](DECISIONS.md) | 🔴 | — |
| P5-4 | Guides | RAG, agents, MCP, security, observability, deployment | 🔴 | — |
| P5-5 | Runnable demo scripts | Six use cases + four negative cases | 🔴 | P4-1 |

## Phase 6 · Articles (week 10 onward)

The **hub article**, then **16 sub-articles** in five groups. Each is its own backlog item.

| ID | Item | Group | Status | Blocked by |
|----|------|-------|:------:|------------|
| P6-1 | Hub article | — | 🔴 | — |
| P6-2 | Kubernetes for .NET developers | Foundations | 🔴 | — |
| P6-3 | Azure security fundamentals | Foundations | 🔴 | — |
| P6-4 | Observability end to end | Foundations | 🔴 | — |
| P6-5 | Supervisor | Orchestration | 🔴 | — |
| P6-6 | Specialist agents | Orchestration | 🔴 | — |
| P6-7 | MCP as the contract | Orchestration | 🔴 | — |
| P6-8 | Enterprise RAG | Retrieval | 🔴 | — |
| P6-9 | Permission-aware retrieval | Retrieval | 🔴 | — |
| P6-10 | Identity propagation | Enterprise concerns | 🔴 | — |
| P6-11 | Bounded autonomy | Enterprise concerns | 🔴 | — |
| P6-12 | Securing agents | Enterprise concerns | 🔴 | — |
| P6-13 | Observability for agents | Enterprise concerns | 🔴 | — |
| P6-14 | Two runtimes on AKS | Platform | 🔴 | — |
| P6-15 | Cost and performance | Platform | 🔴 | — |
| P6-16 | Evaluating agents | Platform | 🔴 | — |
| P6-17 | Environment lifecycle from a pipeline | Platform | 🔴 | — |

---

## Changed plan

A running log of what moved and why, so future readers see the reasoning rather than just
the current state. Append — don't rewrite history.

- **7 Nov 2026** — Initial plan created. 47 items across seven phases (0–6), all 🔴. Built
  from the locked decisions D1–D10. The plan is expected to change as the build teaches
  things; every material move is logged here with its reason.

- **7 Nov 2026** — **Code moved in from the earlier AntKart platform repo.** P0-4 done, P0-3
  mostly done. What came across, and the decisions taken while moving:

  - **`AK.BuildingBlocks`** — copied, with `Messaging/` (MassTransit, Service Bus, Event Grid,
    integration events, notifications) and `Email/` (ACS) **removed**, along with four package
    references and the gRPC and Cosmos OpenTelemetry sources. This reference has no saga and no
    notification path, so none of it earns its place.
  - **12 Terraform modules**, not 18. Dropped: `cosmosdb`, `servicebus`, `eventgrid`,
    `function-app`, `communication-services` — nothing uses them. Also dropped
    `role-assignments`: it turned out to be a purpose-built composition for the Function App's
    system-assigned identity, and `workload-identity` already grants per-service roles
    generically. Catalogue therefore goes on **PostgreSQL**, not Cosmos — one fewer resource to
    pay for and explain, and the Domain/Application layers port unchanged either way. Reversible:
    bringing `cosmosdb` back is one `cp`.
  - **One environment (`dev`)**, with every resource name composed from a single `project` local
    in `root.hcl` and read back by units through `include.root.locals`. A second environment is a
    copy of the folder with one value changed.
  - **Two values that were hardcoded in the old repo are now never committed**: the budget alert
    email (`AK_ALERT_EMAIL`, fails loudly if unset) and the developer firewall IP (`AK_CLIENT_IP`,
    the rule is simply not created if unset). A real Entra client id was also found hardcoded in
    a BuildingBlocks test constant and replaced with an obviously-fake one.
  - **Helm**: one generic chart for all seven workloads including the Python orchestrator — the
    only contract is the port and the two health paths. Two fixes while moving: the chart now
    hashes its ConfigMaps into a pod annotation, so a config change actually rolls the pods
    instead of showing Synced-but-stale; and the gRPC TCP-probe branch is gone.
  - **Argo CD**: the ApplicationSet only. The old repo's parallel standalone `Application`
    manifests created the same names and silently reverted each other's parameters.
  - **CI/CD**: restructured from one full copy per service (12 files, 14 would have been needed
    here) into **three reusable workflows plus fourteen thin callers**. The CD workflow turned out
    to be runtime-agnostic, so the Python orchestrator uses the same one as the .NET services.
    Validated with `actionlint`, clean.
  - **Gateway Ocelot routes rewritten** for the new services, plus an `/gateway/agent/*` route to
    the orchestrator with a 170s timeout and a 2 req/s limit — an agent run is neither as fast nor
    as cheap as a REST call, and the old 10s timeout would have severed it mid-run.

  **Not verified**: there is no .NET SDK, `terraform`, `terragrunt` or `helm` in the session this
  was done in, so `dotnet build`, `terragrunt validate` and `helm template` have NOT been run.
  Syntax was checked by parsing every HCL and YAML file, cross-checking every unit input against
  its module's declared variables, and cross-checking every `.Values.*` reference in the chart
  against the merged values. `actionlint` passed. **Run the three real checks before trusting any
  of it.**
