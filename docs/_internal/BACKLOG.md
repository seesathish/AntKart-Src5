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
| P0-3 | Repo skeleton and solution structure | Folders, `.sln`, placeholder project layout — no services yet | 🔴 | — |
| P0-4 | Terraform + Terragrunt adapted | From the earlier AntKart repo; renamed and parameterised by project prefix (D8) | 🔴 | — |
| P0-5 | Budget alert on the resource group | Cost discipline is real — personal Azure account | 🔴 | — |

## Phase 1 · Platform (weeks 1–3)

| ID | Item | Detail | Status | Blocked by |
|----|------|--------|:------:|------------|
| P1-1 | Lifecycle workflows | `infra-up`, `infra-down`, `infra-plan`, `env-stop`, `env-start` (D8) | 🔴 | P0-4 |
| P1-2 | Core Azure resources | Provisioned and verified from the pipelines | 🔴 | P1-1 |
| P1-3 | AKS, Argo CD, ingress, cert-manager | Cluster and GitOps delivery baseline | 🔴 | P1-2 |
| P1-4 | Five .NET services deployed | Gateway, Users, Catalogue, Cart, Orders — deployed and healthy (D3) | 🔴 | P1-3 |
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
