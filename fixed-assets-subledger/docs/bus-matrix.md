# Fixed Assets — Kimball Bus Matrix (Oracle Fusion 25C)

This matrix documents the **business processes (facts)** and their **conformed dimensions**. Facts must remain at their **natural grain**; do not blend subledger/SLA/GL into a single table.

| Business Process            | Fact Table / Grain                                                | D_Asset | D_Book | D_Time Key | D_COA (CCID) | D_Category | D_Location | Other Dims        |
|-----------------------------|-------------------------------------------------------------------|:------:|:------:|:----------:|:------------:|:----------:|:----------:|-------------------|
| Asset Transactions          | `F_Asset_Transaction` — one row per **transaction header** *(or per header×CCID at distribution grain)* |   ✔    |   ✔    |  TRX_DATE  |      ✔       |     ✔      |   ✔ (opt.) | D_TrxType         |
| Asset Depreciation Period   | `F_Depreciation_Period` — one row per **asset×book×period**      |   ✔    |   ✔    |   PERIOD   |   (opt.)*    |     ✔      |   ✔ (opt.) | —                 |
| Asset Balance Period        | `F_Asset_Balance_Period` — one row per **asset×book×period snapshot** | ✔   |   ✔    |   PERIOD   |      —       |     ✔      |   ✔ (opt.) | —                 |

\* Include CCID only if depreciation is allocated by account in your tenancy; otherwise omit to keep period facts slim.

## Notes
- **Conformed dimensions:** `D_Asset`, `D_Book`, `D_Time`, `D_COA (by CODE_COMBINATION_ID)`, `D_Category`, `D_Location`.
- **Grain guardrails:** Transactions = event grain; Depreciation = period grain; Balances = period snapshot.  
- **Reconciliation:** Perform subledger rollforwards at the period grain; any SLA/GL reconciliation should use **separate** facts and mapping tables, not blended rows.

## Roadmap (extensibility)
Future subject areas plug into the same bus:
- **AP Invoices → FA Additions** (capitalizations): add `F_AP_InvoiceLines` and reuse `D_COA`, `D_Time`, `D_Supplier`.
- **Projects → CIP → FA**: add `F_Project_Cost` and reuse `D_COA`, `D_Time`, `D_Project`.
- **Leases** (if adopted): add `F_Lease_Amortization` with `D_Asset` (leased asset), `D_Book`, `D_Time`, `D_COA`.

**Version:** 25C
