# Data Lineage

## Fixed Assets

Oracle Fixed Assets ESS reporting extract → OTBI (BIP Logical SQL) → CSV partitions → Power BI model

Later: BICC PVOs → Fabric Lakehouse → same star schema

Oracle 26B documents the Fixed Assets OTBI subject areas as extract-backed:

- `Fixed Assets - Asset Transactions Real Time`: distribution-line grain via `FA_TRX_EXTRACT`
- `Fixed Assets - Asset Depreciation Real Time`: depreciation-distribution grain via `FA_DEPRN_EXTRACT`
- `Fixed Assets - Asset Balances Real Time`: transaction-distribution-line grain via `FA_BALANCES_EXTRACT`

## Accounts Payable — Aging

Oracle Fusion base tables → BIP direct SQL (`sql/bip/ap_*.sql`) → CSV partitions → Power BI model

Sources:

- `AP_PAYMENT_SCHEDULES_ALL` — schedule-level open exposure (`AMOUNT_REMAINING`)
- `AP_INVOICES_ALL` — invoice header context
- `AP_INVOICE_DISTRIBUTIONS_ALL` — distribution drill-through and invoice-level classification bridge

Layered reference SQL under `sql/ap/` mirrors staging → intermediate → marts for review and future Fabric deployment.

Supplier spend history (separate grain):

- `AP_INVOICE_DISTRIBUTIONS_ALL` → `XLA_DISTRIBUTION_LINKS` → `XLA_AE_HEADERS` (contract: `supplier_history`)

Do not blend supplier spend history grain with AP aging schedule grain.
