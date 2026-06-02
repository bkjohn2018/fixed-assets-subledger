# Accounts Payable — Kimball Bus Matrix (Oracle Fusion 26B)

This matrix documents AP business processes and conformed dimensions. Facts remain at their **natural grain**. Do not join payment schedules to invoice distributions and sum schedule open amounts.

| Business Process | Fact Table / Grain | D_Supplier | D_Time (DUE_DATE) | D_COA | D_BusinessUnit | Notes |
|------------------|-------------------|:----------:|:-------------------:|:-----:|:--------------:|-------|
| AP Aging Schedule | `F_AP_Aging_Schedule` — one row per **payment schedule × as-of date** | ✔ | ✔ | — | ✔ (ORG_ID) | Primary exposure model; `AMOUNT_REMAINING` is additive |
| AP Invoice Distribution | `F_AP_Invoice_Distribution` — one row per **invoice distribution** | ✔ | — | ✔ | ✔ | Drill-through for COA, project, PO, asset flags |
| Supplier Spend History | `Supplier_History` — one row per **distribution accounting event** | ✔ | ✔ (GL_DATE) | ✔ | — | SLA-linked spend; not open-balance aging |

## Grain guardrails

- **Aging:** `AP_PAYMENT_SCHEDULES_ALL` at `INVOICE_ID` + `PAYMENT_NUM` + `AS_OF_DATE`. Open amount = `AMOUNT_REMAINING`.
- **Distribution bridge:** Invoice-level flags from `AP_INVOICE_DISTRIBUTIONS_ALL` aggregated to `INVOICE_ID`. Merged into aging via LEFT JOIN only.
- **Anti-pattern:** `payment_schedules JOIN invoice_distributions` then `SUM(amount_remaining)` — overstates exposure.

## Bridge columns on aging fact (non-additive)

`DISTRIBUTION_TOTAL_AMOUNT`, `DISTRIBUTION_COUNT`, and related bridge fields classify invoices. Do not add them to `[AP Open Amount]` or other schedule-level measures.

## Reconciliation

- Run `sql/ap/diagnostics/ap_aging_reconciliation_checks.sql` after each extract.
- Run `sql/ap/diagnostics/ap_status_value_profiles.sql` when tuning credit memo or status CASE logic.
- Tie `SUM(AMOUNT_REMAINING)` to `AP_PAYMENT_SCHEDULES_ALL` under identical open-balance filters.

## Reporting patterns (Power BI measures)

| View | Primary table | Key measures |
|------|---------------|--------------|
| Executive aging summary | `F_AP_Aging_Schedule` | `[AP Open Amount]`, `[AP Held Amount]`, `[AP Open Credits]` by `AGING_BUCKET` |
| Supplier aging detail | `F_AP_Aging_Schedule` | Row-level `AMOUNT_REMAINING`, `AGING_BUCKET`, hold fields |
| Credit memo diagnostics | `F_AP_Aging_Schedule` + diagnostics SQL | `[AP Open Credits]`, `IS_CREDIT_MEMO` = 1 |
| Project-related aging | `F_AP_Aging_Schedule` | `[AP Project Related Amount]`, `HAS_PROJECT_DISTRIBUTION` |

**Version:** 26B
