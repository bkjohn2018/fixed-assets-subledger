# Fixed Assets — Kimball Bus Matrix (Oracle Fusion 26B)

This matrix documents the **business processes (facts)** and their **conformed dimensions**. Facts must remain at their **natural grain**; do not blend subledger/SLA/GL into a single table.

| Business Process            | Fact Table / Grain                                                | D_Asset | D_Book | D_Time Key | D_COA (CCID) | D_Category | D_Location | Other Dims        |
|-----------------------------|-------------------------------------------------------------------|:------:|:------:|:----------:|:------------:|:----------:|:----------:|-------------------|
| Asset Transactions          | `F_Asset_Transaction` — one row per **transaction distribution line** |   ✔    |   ✔    |  TRX_DATE  |      ✔       |     ✔      |   ✔ (opt.) | D_TrxType         |
| Asset Depreciation Period   | `F_Depreciation_Period` — one row per **asset×book×period**, aggregated from OTBI depreciation distribution rows |   ✔    |   ✔    |   PERIOD   |   —    |     ✔      |   — | —                 |
| Asset Balance Period        | `F_Asset_Balance_Period` — one row per **asset×book×period snapshot**, aggregated from OTBI balance distribution rows | ✔   |   ✔    |   PERIOD   |      —       |     ✔      |   — | —                 |

## Notes
- **Conformed dimensions:** `D_Asset`, `D_Book`, `D_Time`, `D_COA (by CODE_COMBINATION_ID)`, `D_Category`, `D_Location`.
- **Grain guardrails:** Transactions = distribution-line grain; Depreciation = aggregated period grain; Balances = aggregated period snapshot. Oracle 26B documents the OTBI subject areas as extract-backed distribution-grain sources, so aggregate only where the contract explicitly says period grain.
- **Reconciliation:** Perform subledger rollforwards at the period grain; any SLA/GL reconciliation should use **separate** facts and mapping tables, not blended rows.

## Related P2C domains

AP (Pay stage) is documented in [`../ap/bus-matrix.md`](../ap/bus-matrix.md), and active Projects (Collect stage) in [`../projects/bus-matrix.md`](../projects/bus-matrix.md). Procurement remains planned — see [`../../conceptual/capex-lifecycle.md`](../../conceptual/capex-lifecycle.md) and [`../../conceptual/procure-to-capitalize.md`](../../conceptual/procure-to-capitalize.md).

Cross-stage links (e.g. AP distributions → FA additions) use bridge keys and conformed dimensions; do not grain-blend facts.

**Version:** 26B
