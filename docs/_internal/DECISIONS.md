# Architectural decisions — locked

The decisions below are **locked**. They exist so they are never re-litigated mid-build. If
one genuinely has to change, supersede it with a new dated entry rather than editing the old
one in place — the reasoning is the asset.

Each entry records: **decision · what was chosen · why · what was rejected · date decided.**

---

## D1 · Multi-agent orchestration — supervisor pattern

- **Chosen:** A **supervisor (orchestrator) pattern** — one routing node that delegates to specialist agents and owns the control flow.
- **Why:** Supervisor is the 2026 production default. It has the widest native framework support, the best-understood failure mode (over-delegation, bounded by iteration ceilings), and the clearest traces — one routing node, every decision visible and reconstructable.
- **Rejected:** **Swarm** (peer-to-peer handoff — harder to debug, diffuse control flow); **single-agent** (does not demonstrate orchestration, which is the explicit ask).
- **Decided:** 7 Nov 2026.

## D2 · Python orchestration layer, .NET system of record, MCP as the boundary

- **Chosen:** The .NET services stay **unchanged** and expose typed tools through an **MCP server**; a **Python orchestrator (LangGraph)** consumes them. MCP is the contract between the two runtimes.
- **Why:** The scenario being demonstrated is an **existing enterprise .NET application gaining multi-agent orchestration without a rewrite**. The AI ecosystem is Python and fighting it is wasted effort, while the .NET services are the thing enterprises actually have — so the integration boundary *is* the demonstration.
- **Rejected:** **Pure .NET orchestration with Microsoft Agent Framework** — viable, and worth covering comparatively in the articles, but it does not demonstrate the .NET/Python integration problem real migrations face. **Rewriting the services in Python** — throws away the entire premise.
- **Decided:** 7 Nov 2026.

## D3 · Five .NET services + one MCP server + one Python orchestrator

- **Chosen:** Five .NET services — **Gateway, Users, Catalogue, Cart, Orders** — plus one MCP server and one Python orchestrator.
- **Why:** Enough domain surface for genuine multi-agent routing, small enough to build in ten weeks. **Users** is included specifically because identity propagation is the central security demonstration (see D5).
- **Rejected:** Fewer services (not enough surface for real routing); more services (not buildable in the window).
- **Decided:** 7 Nov 2026.

## D4 · Four specialist agents under one supervisor

- **Chosen:** Four specialists — **Catalogue** (search, RAG, comparison), **Cart** (stateful, reversible writes), **Orders** (status, placement), **Support** (RAG over policy documents).
- **Why:** Four gives genuine multi-domain routing without sprawl. The number is **deliberate** — resist adding more; each extra agent multiplies routing ambiguity and trace noise.
- **Rejected:** A larger agent roster (routing ambiguity, harder traces, no added teaching value).
- **Decided:** 7 Nov 2026.

## D5 · Identity propagation, not service identity

- **Chosen:** The **calling user's token travels** through gateway → orchestrator → MCP server → each service, so downstream services enforce **user-level** access control.
- **Why:** This follows the **AWS Well-Architected Agentic AI Lens** best practice. The anti-pattern — the agent acting under its own privileged identity — is exactly what lets a single prompt injection read every user's data. Identity propagation contains the blast radius to what the *actual caller* may see.
- **Rejected:** **Service/agent identity** (the agent holds a broad privileged identity and acts on the user's behalf) — the injection blast-radius anti-pattern.
- **Decided:** 7 Nov 2026.

## D6 · Human-in-the-loop gate on irreversible actions only

- **Chosen:** **Order placement** requires explicit user confirmation — the agent **proposes** a structured order and nothing commits until approved. **Cart** operations are reversible and need no gate.
- **Why:** Real HITL means the human can **prevent** the action, not review it after the fact. Gating everything trains users to rubber-stamp; gating only irreversible actions keeps the gate meaningful.
- **Rejected:** Gate on every action (approval fatigue, meaningless gate); gate nothing (no prevention of irreversible mistakes); after-the-fact review (not prevention).
- **Decided:** 7 Nov 2026.

## D7 · Bounded autonomy

- **Chosen:** A **step cap**, a **token budget**, a **recursion guard on handoff count**, and **idempotent tools** so retries are safe.
- **Why:** A multi-agent system without a recursion guard is a production incident waiting to happen — an unbounded loop is an open-ended bill and an open-ended blast radius. Bounds make the system's worst case knowable.
- **Rejected:** Unbounded loops / "trust the model to stop"; non-idempotent tools (unsafe retries).
- **Decided:** 7 Nov 2026.

## D8 · Environment lifecycle through pipelines, not manual Terraform

- **Chosen:** **GitHub Actions** workflows provision and destroy the entire environment on one click, with a **project-prefix input** so two people can run it simultaneously without colliding on globally-unique names.
- **Why:** Adoption depends on **clone-and-run**. A reference implementation nobody can stand up is a demo, not a reference; manual Terraform steps are where adopters give up.
- **Rejected:** Manual `terraform apply`/`destroy` as the documented path (adoption friction, name collisions between concurrent users).
- **Decided:** 7 Nov 2026.

## D9 · Repo name and relationship

- **Chosen:** **AntKart-Src5 is the internal build repo.** A clean **public repo** is published from it later. Internal material — this `docs/_internal/` folder, build history, known-issues registers, playbooks — **never reaches the public copy**. Older AntKart repos become private once this is in shape.
- **Why:** Keeps the public artefact clean and history-free while preserving the honest internal record (decisions, gaps, false starts) that makes the work credible to its builder.
- **Rejected:** A single public-from-day-one repo (leaks internal planning and history); no separation (public copy carries noise).
- **Decided:** 7 Nov 2026.

## D10 · Negative cases are first-class

- **Chosen:** Four negative cases are **built and demonstrated deliberately** — **prompt injection via retrieved content**, **cross-user access attempt**, **runaway tool loop**, and **hallucinated action rejected by schema validation**.
- **Why:** These are what separate a **reference implementation** from a demo. Showing that the system *fails safely* under adversarial input is the most credible thing an enterprise reference can do.
- **Rejected:** Happy-path only (a demo, not a reference); describing the negative cases without building them (unfalsifiable claims).
- **Decided:** 7 Nov 2026.
