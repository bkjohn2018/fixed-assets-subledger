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

## Related AP domain

AP aging and supplier spend are documented in [`bus-matrix-ap.md`](bus-matrix-ap.md). They use separate facts from Fixed Assets and must not be grain-blended.

## Roadmap (extensibility)
Future subject areas plug into the same bus:
- **AP Invoices → FA Additions** (capitalizations): add `F_AP_InvoiceLines` and reuse `D_COA`, `D_Time`, `D_Supplier`.
- **Projects → CIP → FA**: add `F_Project_Cost` and reuse `D_COA`, `D_Time`, `D_Project`.
- **Leases** (if adopted): add `F_Lease_Amortization` with `D_Asset` (leased asset), `D_Book`, `D_Time`, `D_COA`.

**Version:** 26B
