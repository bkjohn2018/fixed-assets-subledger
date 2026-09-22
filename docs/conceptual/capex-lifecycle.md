# Capital Expenditure Lifecycle (Conceptual Model)

This document defines the **platform conceptual model** for capital investment analytics on Oracle Fusion. It follows DAMA/DMBOK layering: conceptual (this doc) → logical (bus matrices, contracts) → physical (SQL, Power BI).

**Boardroom name:** Capital Expenditure Lifecycle (CapEx Lifecycle)  
**Domain process vocabulary:** [Procure-to-Capitalize (P2C)](procure-to-capitalize.md) — Procure → Pay → Collect → Capitalize

## Scope

CapEx Lifecycle analytics covers how capital investment flows from spend through in-service assets:

```text
Procure → Pay → Collect → Capitalize
```

Each stage is a separate **subject area** with its own facts at natural grain. The platform value is **conformed dimensions and traceability** across stages—not a single blended fact.

## Domain registry

| CapEx stage | P2C stage | Domain folder | Status |
|-------------|-----------|---------------|--------|
| Commitment | Procure | `procurement/` | Planned |
| Spend & payables | Pay | `ap/` | Active |
| Cost collection | Collect | `projects/` | Active |
| In-service assets | Capitalize | `fa/` | Active |

Bus matrices: [`../domains/fa/bus-matrix.md`](../domains/fa/bus-matrix.md), [`../domains/ap/bus-matrix.md`](../domains/ap/bus-matrix.md), [`../domains/projects/bus-matrix.md`](../domains/projects/bus-matrix.md)

## Conformed business concepts

Shared across CapEx stages. See [`../platform/conformed-dimensions.md`](../platform/conformed-dimensions.md).

- **Supplier**, **Project**, **COA**, **Asset**, **Time**, **Org**

## Cross-stage traceability

Links use **bridge keys and mapping tables**, not grain-blended facts. In the active Projects domain, traceability runs from project cost distribution through project asset-line detail and project asset line to capitalization status and posted `ASSET_ID`. See [P2C process model](procure-to-capitalize.md) for stage-to-stage keys.

Projects candidate flags are governed review indicators based on Oracle-recorded eligibility, aging, holds, and posted evidence. They are not accounting conclusions, error assertions, or authorization to capitalize.

## Logical and physical layers

| Layer | Artifacts |
|-------|-----------|
| Conceptual | This doc, [P2C process model](procure-to-capitalize.md) |
| Logical | `docs/domains/*/bus-matrix.md`, `contracts/<domain>/*.yml` |
| Physical | `sql/bip/<domain>/`, `sql/<domain>/`, `powerbi/queries/<domain>/` |

See [`../platform/change-discipline.md`](../platform/change-discipline.md) for the contract-first change order.

## Out of scope

- GL/SLA reconciliation as a blended fact
- Application backends, deployment configs, local exports, secrets
- Lease accounting (future domain if adopted)

**Version:** 26B
