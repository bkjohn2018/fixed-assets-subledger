# Procure-to-Capitalize (P2C Process Model)

Domain process vocabulary for the [Capital Expenditure Lifecycle](capex-lifecycle.md). Use **P2C** in bus matrices, contracts, and cross-domain discussions; use **CapEx Lifecycle** for platform and executive framing.

## P2C stages

Capital investment flows through four stages. Each stage is a separate subject area with its own facts at natural grain.

```text
Procure          Pay              Collect            Capitalize
(PO/commitment) → (AP invoice/pay) → (Project/CIP cost) → (FA asset/NBV)
```

| P2C stage | Domain folder | Status | Primary questions |
|-----------|---------------|--------|-------------------|
| Procure | `procurement/` | Planned | Commitments, PO open qty/amount, receipt vs invoice |
| Pay | `ap/` | Active | Open exposure, supplier spend, invoice drill-through |
| Collect | `projects/` | Active | Cost collection, asset assignment, capitalization workflow, source-to-FA traceability |
| Capitalize | `fa/` | Active | NBV, depreciation, rollforward, retirements |

## Cross-stage relationships

Traceability across P2C uses **bridge keys and mapping tables**, not grain-blended facts:

- Procure ↔ Pay: PO distribution / matching keys
- Pay ↔ Collect: AP distribution `PJC_PROJECT_ID` / task context to conformed `PROJECT_ID` and `TASK_ID`; preserve AP and project-cost grains
- Collect internal lineage: `EXPENDITURE_ITEM_ID` + `LINE_NUM` → `PJC_PRJ_ASSET_LN_DETS` → `PROJECT_ASSET_LINE_ID`
- Collect ↔ Capitalize: project asset line → mass-addition workflow → posted `FA_ASSET_INVOICES.ASSET_ID`
- All stages ↔ COA: `CODE_COMBINATION_ID` / `DIST_CODE_COMBINATION_ID`

The Projects status snapshot distinguishes generated, held, rejected, transferred, and posted lifecycle states without blending their amounts. A capitalization-candidate flag routes an aged, Oracle-capitalizable item for human review; it does not determine accounting treatment, prove an error, or authorize capitalization.

**Version:** 26B
