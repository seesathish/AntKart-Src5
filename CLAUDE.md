# AntKart-Src5 — Claude Code instructions

Conventions and rules for this repository. Read it fully before starting any task.

---

## What this is

An enterprise **.NET reference implementation** showing how an *existing* .NET application gains
**multi-agent AI orchestration without being rewritten**. The .NET services stay as they are and
expose typed tools through an MCP server; a Python (LangGraph) supervisor orchestrates four
specialist agents over them.

The audience is engineers who will adopt this for their own projects. **Clone-and-run and honest
security matter more than a polished demo.** A reader who cannot stand it up, or who is shown a
security model that quietly does not hold, has got nothing from it.

## Repository model — read this before writing any document

This repo (`AntKart-Src5`) is the **internal working repository**. A separate **public repository**
will be published from it later as a history-free copy with internal-only material removed.

**Assume everything you write may be published**, unless it sits in an internal-only path.

### Internal-only — will NOT exist in the public repo
- `docs/_internal/` — `PROJECT-STATE.md`, `DECISIONS.md`, `BACKLOG.md` (already gitignored)
- `CLAUDE.md` — this file

### Rules
- **No document intended for the public repo may link into an internal-only path.** If a public
  doc needs to explain a decision, state the reasoning in prose rather than linking to
  `DECISIONS.md`.
- **No build stories, known-issues registers, playbooks or internal references** in published
  paths. That material belongs in `docs/_internal/` or not in this repo at all.
- **No personal data, anywhere.** No email addresses, no public IP addresses, no tenant or
  subscription GUIDs, no domain names of Sathish's own. Where a real value is needed, read it from
  an environment variable or leave it empty with a comment saying where it comes from. Several
  places already do this — follow the existing pattern rather than inventing a new one.

## The architecture — locked, do not re-litigate

```
User → Gateway (.NET) → Orchestrator (Python, LangGraph supervisor + 4 specialist agents)
     → MCP server (.NET, typed tools) → Catalogue · Cart · Orders · Users (.NET)
```

The **user's bearer token propagates along every hop**, and each service validates it itself
rather than trusting the hop in front of it. The **HITL gate** sits at the Orders agent: order
placement is *proposed*, never committed, until the user confirms.

Ten decisions are locked in `docs/_internal/DECISIONS.md` as **D1–D10**. Do not reopen them
mid-build. If the build genuinely contradicts one, say so plainly and propose a dated
supersession — do not drift.

## Layout

```
AntKart-Src5/
├── AK.BuildingBlocks/     Shared cross-cutting library (no business logic)
├── deploy/                Kubernetes delivery — Helm chart + Argo CD + cert-manager
├── infrastructure/        Terraform modules + Terragrunt units
├── .github/workflows/     Reusable CI/CD workflows + thin per-service callers
├── docs/_internal/        Planning material (gitignored)
├── AntKart.sln
├── nuget.config
└── CLAUDE.md              ← this file
```

Still to be created (see `BACKLOG.md`): `AK.Gateway`, `AK.Users`, `AK.Catalogue`, `AK.Cart`,
`AK.Orders`, `AK.Mcp`, and `orchestrator/` (Python). The CI/CD workflows for all seven already
exist and are dormant until their folders do.

Each .NET service folder contains all its layers and its test project:

```
AK.<Service>/
  AK.<Service>.Domain/
  AK.<Service>.Application/
  AK.<Service>.Infrastructure/
  AK.<Service>.API/
  AK.<Service>.Tests/
```

## Three names that must stay in lockstep

This is the single most common way to break this platform silently.

```
infrastructure  services.<key>.service_account_name = "ak-catalogue"
deploy          values/catalogue.yaml → name: ak-catalogue
Entra           subject system:serviceaccount:antkart:ak-catalogue
```

The federated-credential subject is matched **exactly and case-sensitively**. Rename a Kubernetes
ServiceAccount — or the namespace — and workload identity breaks *silently*: the pod starts
cleanly, and the first Azure call fails with a credential error that says nothing about naming.
Change one of the three and change all three.

## What is deliberately NOT here

Carried over from the earlier platform and dropped on purpose. Do not add them back without a
reason recorded in `DECISIONS.md`.

| Dropped | Why |
|---|---|
| MassTransit / Service Bus | No saga in this reference. The HITL gate is synchronous. |
| Event Grid, ACS email, Azure Functions | No notification path. |
| Cosmos DB | One relational store is enough, and cheaper on a personal subscription. |
| gRPC | No gRPC service, so no gRPC instrumentation or TCP probe branch either. |
| Standalone Argo CD `Application` manifests | They duplicated the ApplicationSet and silently reverted its parameters. |

## Security conventions

**Workload identity is not user identity.** Every managed identity in `infrastructure/` is a
*service's* identity, used to reach Azure resources. It is deliberately not how the platform
decides what data a caller may see — that is the user's own token.

- **Never** accept a `userId` as a path parameter or a request-body field for user-scoped
  operations. Derive it from the JWT via `http.GetUserId()` (BuildingBlocks).
- **Never** let the MCP server or an agent call a service with its own identity on a user's
  behalf. If it did, every tool call would run with the server's permissions instead of the
  user's, and the cross-user negative case (D10) would pass.
- `UnauthorizedAccessException` maps to HTTP 403 in `ExceptionHandlerMiddleware`.
- Ownership is enforced **in the service that owns the data**, not in the agent and not in the
  gateway. An agent declining to ask is not access control.

## Coding conventions

- `net9.0`, `<Nullable>enable</Nullable>`, `<ImplicitUsings>enable</ImplicitUsings>` everywhere.
- **No comments unless the WHY is non-obvious** — a hidden constraint, a workaround, a subtle
  invariant. No XML doc comments.
- Minimal API endpoint classes, not `[ApiController]`.
- CQRS with MediatR; commands and queries return DTOs or primitives, **never domain entities**.
- FluentValidation validators in `Application/Validators/`, wired through `ValidationBehavior`.
- Domain entities: private setters, a `Create(...)` factory, no EF attributes. EF configuration is
  fluent API in Infrastructure.
- DTOs are `record` types in Application; mappers are `internal static` extension classes. No
  AutoMapper.
- No cross-service entity references — denormalise.
- Layer dependencies, enforced by `ProjectReference`:
  `Domain ← (nothing)`, `Application ← Domain + BuildingBlocks`, `Infrastructure ← Application`,
  `API ← Application + Infrastructure + BuildingBlocks`, `Tests ← Application + Infrastructure +
  Domain` (never API).
- Always wire `AddSerilogLogging()`, `AddOpenTelemetryObservability()`, `AddDefaultHealthChecks()`
  and `MapDefaultHealthChecks()` in `Program.cs`.
- **Every workload serves `/health/live` and `/health/ready` on `containerPort`** — including the
  Python orchestrator. That contract is why one Helm chart deploys both runtimes.

### Tests
XUnit + Moq + FluentAssertions. Pure unit tests: no database, no network, no running host. Mock
via interface, never a concrete class. Naming: `Method_Condition_ExpectedResult`.

**A test must not carry a real directory's identifiers.** Use obviously-fake fixtures.

## NuGet

A private Azure DevOps feed in the machine-level NuGet config returns 401. The root
`nuget.config` clears inherited sources and adds only nuget.org. **Always `dotnet restore` from
the repo root** so it is picked up. Never add `--ignore-failed-sources`.

Pin versions. The OpenTelemetry packages are held on the **1.13.x** line — the last that depends
on `Microsoft.Extensions.*` 9.0.0; 1.14.0+ requires 10.x and breaks this solution.

## Build and test

```bash
dotnet restore          # from the repo root
dotnet build
dotnet test
```

## Rules for Claude Code in this repository

- **Do not run `git commit`, `git push`, `git remote` or `git filter-branch`.** Staging and
  committing are reviewed by hand. Report what you changed and stop.
- **Verify against the repository, not against documentation or memory.** Read the file before
  asserting what is in it.
- **Report ambiguity rather than deciding it.** If a task is underspecified, say what is missing
  and what you would assume — do not pick silently and build on it.
- **Do not invent values.** No placeholder GUIDs that look real, no guessed resource ids, no
  fabricated endpoints. Leave it empty with a comment naming its source.
- When adding a service, update `AntKart.sln`, add the CI/CD caller pair, add its
  `deploy/helm/values/<service>.yaml`, add its element to the ApplicationSet, and add its identity
  to the `workload-identity` unit. Missing the last one is the silent-failure case above.
