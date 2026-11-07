# AntKart — agentic AI reference implementation

How an **existing .NET application** gains **multi-agent AI orchestration without being
rewritten**. The .NET services stay as they are and expose typed tools through an MCP server; a
Python supervisor orchestrates four specialist agents over them.

> **Status: under construction.** The platform and delivery layers are in place; the services and
> the agent runtime are not written yet. See *What is here* below for exactly what exists today.
> This is the internal working repository — a clean public copy is published from it separately.

## The shape of it

```
User ──bearer token──▶ Gateway (.NET)
                          │  token propagates
                          ▼
                   Orchestrator (Python · LangGraph supervisor)
                          │
            ┌─────────────┼─────────────┬──────────────┐
         Catalogue      Cart         Orders         Support      ← four specialist agents
          agent         agent     (HITL gate)        agent
            └─────────────┴─────────────┴──────────────┘
                          │
                          ▼
                   MCP server (.NET · typed tools)
                          │  token propagates
            ┌─────────────┼─────────────┬──────────────┐
         Catalogue      Cart         Orders          Users        ← five .NET services,
                                                                    with the Gateway above
```

Three things are doing the work here:

**The user's token propagates along every hop**, and each service validates it itself rather than
trusting the hop in front of it. The agent never acts with its own permissions on a user's behalf.
That is what makes an agent which has been talked into asking for someone else's data get refused
by the service, rather than relying on the agent to decline.

**The MCP server is a typed boundary**, not a convenience. A tool schema is a contract the model
is held to, so an agent that invents a field or a value is rejected before any service is touched.

**The gate is on the irreversible action only.** Cart writes are reversible, so the agent makes
them freely; order placement is proposed and waits for a human. Gating everything would train the
user to click through confirmations without reading them, which is worse than having no gate.

## What is here

| | |
|---|---|
| `infrastructure/` | 12 Terraform modules and 12 Terragrunt units — resource group, networking, AKS, Key Vault, PostgreSQL, Redis, observability, Entra app registration, workload identity, GitHub OIDC, container registry, budget |
| `deploy/` | One generic Helm chart for all seven workloads, an Argo CD ApplicationSet, cert-manager ClusterIssuers |
| `.github/workflows/` | Three reusable workflows and fourteen thin callers — CI gate per workload, OIDC delivery to ACR, GitOps tag bump |
| `AK.BuildingBlocks/` | Shared library — Entra token validation, health checks, OpenTelemetry, Serilog, resilience, DDD base types |

## What is not here yet

The five .NET services, the .NET MCP server, the Python orchestrator, and the `ai-search` and
`openai` infrastructure modules. The CI/CD workflows for all seven workloads already exist and are
dormant until their folders do.

## Running it

Nothing here is free to run. AKS, PostgreSQL and the model endpoint all bill by the hour, so the
environment is built to be **stopped between sessions** and a budget alert is provisioned early
and deliberately. Note that a stopped PostgreSQL Flexible Server **auto-starts after 7 days**.

Start with [`infrastructure/README.md`](infrastructure/README.md) for provisioning, then
[`deploy/README.md`](deploy/README.md) for delivery. Both name the handful of values you have to
supply yourself — a tenant, a domain, an email — because they identify your directory, not
somebody else's.
