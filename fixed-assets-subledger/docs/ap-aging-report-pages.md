# AP Aging — Power BI report pages

Scaffolded in `powerbi/FixedAssetsSubledger.Report` (`.pbip`).

## Page order

| # | Display name | Internal name | Audience |
|---|--------------|---------------|----------|
| 1 | Overview | `fa2233445566778899aa` | Fixed Assets landing (existing) |
| 2 | Executive Aging Overview | `ap_exec2233445566778801` | Leadership |
| 3 | Operational Resolution Queue | `ap_oper2233445566778802` | AP operations |
| 4 | Financial / Project Impact | `ap_finp2233445566778803` | Finance / project accounting |

Default active page on open: **Executive Aging Overview**.

## Build checklist (per page)

Wire the semantic model (`FixedAssetsSubledger.SemanticModel`) with:

- `F_AP_Aging_Schedule` partition from `powerbi/queries/F_AP_Aging_Schedule.m`
- `F_AP_Invoice_Distribution` from `F_AP_Invoice_Distribution.m`
- Measures from `powerbi/measures.dax`

Each scaffold page includes a **Planned visuals** text box listing target KPIs, charts, and guardrails. Replace text boxes with cards, charts, and tables as CSV data becomes available.

## Measure reference

| Page | Primary measures |
|------|------------------|
| Executive | `[AP Gross Unpaid Invoices]`, `[AP Past Due Amount]`, `[AP Open Credits]`, `[AP Net Exposure]` |
| Operational | `[AP Held Amount]`, `[AP Open Amount]`, counts by `IS_CREDIT_MEMO`, `AGING_BUCKET` |
| Financial / Project | `[AP Project Related Amount]`, filters on `HAS_*_DISTRIBUTION` bridge columns |

Mockup reference: `ap_aging_workspace_mockup_spec.md` (stakeholder HTML prototype).
