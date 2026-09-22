# Data Lineage

See [`../conceptual/capex-lifecycle.md`](../conceptual/capex-lifecycle.md) for platform scope and [`../conceptual/procure-to-capitalize.md`](../conceptual/procure-to-capitalize.md) for P2C stage map.

## Fixed Assets (Capitalize)

Oracle Fixed Assets ESS reporting extract → OTBI (BIP Logical SQL) → CSV partitions → Power BI model

Later: BICC PVOs → Fabric Lakehouse → same star schema

Oracle 26B documents the Fixed Assets OTBI subject areas as extract-backed:

- `Fixed Assets - Asset Transactions Real Time`: distribution-line grain via `FA_TRX_EXTRACT`
- `Fixed Assets - Asset Depreciation Real Time`: depreciation-distribution grain via `FA_DEPRN_EXTRACT`
- `Fixed Assets - Asset Balances Real Time`: transaction-distribution-line grain via `FA_BALANCES_EXTRACT`

Physical artifacts: `contracts/fa/`, `sql/bip/fa/`, `sql/fa/`, `powerbi/queries/fa/`

## Accounts Payable (Pay)

Oracle Fusion base tables → BIP direct SQL (`sql/bip/ap/`) → CSV partitions → Power BI model

Sources:

- `AP_PAYMENT_SCHEDULES_ALL` — schedule-level open exposure (`AMOUNT_REMAINING`)
- `AP_INVOICES_ALL` — invoice header context
- `AP_INVOICE_DISTRIBUTIONS_ALL` — distribution drill-through and invoice-level classification bridge

Layered reference SQL under `sql/ap/` mirrors staging → intermediate → marts for review and future Fabric deployment.

Physical artifacts: `contracts/ap/`, `sql/bip/ap/`, `sql/ap/`, `powerbi/queries/ap/`

Supplier spend history (separate grain):

- `AP_INVOICE_DISTRIBUTIONS_ALL` → `XLA_DISTRIBUTION_LINKS` → `XLA_AE_HEADERS` (contract: `supplier_history`)

Do not blend supplier spend history grain with AP aging schedule grain.

## Projects (Collect)

Oracle Fusion Projects base tables → BIP direct SQL (`sql/bip/projects/`) → CSV partitions → Power BI model

Verified source-to-FA path:

```text
PJC_COST_DIST_LINES_ALL
  -> PJC_PRJ_ASSET_LN_DETS
  -> PJC_PRJ_ASSET_LNS_ALL / PJC_PRJ_ASSETS_ALL
  -> FA_MASS_ADDITIONS
  -> FA_ASSET_INVOICES
  -> ASSET_ID
```

Dataset ownership preserves each source grain:

- `F_Project_Cost`: `EXPENDITURE_ITEM_ID` + `LINE_NUM`.
- `B_Project_Cost_To_Asset_Line`: `PROJ_ASSET_LINE_DTL_UNIQ_ID` + `PROJECT_ASSET_LINE_ID`; expanded lineage link only and non-additive.
- `F_Project_Asset_Line`: `PROJECT_ASSET_LINE_ID`.
- `F_Project_Capitalization_Status`: `PROJECT_ASSET_LINE_ID` + `AS_OF_DATE`.

A project cost can split across multiple asset-line detail rows. Joining through the bridge therefore repeats the source fact; aggregate cost on `F_Project_Cost`, asset-line cost on `F_Project_Asset_Line`, and posted/candidate amounts on one selected status snapshot.

Physical artifacts: `contracts/projects/`, `sql/bip/projects/`, `sql/projects/`, `powerbi/queries/projects/`

`IS_CAPITALIZATION_CANDIDATE` is a governed review signal derived from Oracle-recorded capitalizable status, aging, absence of a hold, and absence of posted FA evidence. It is not an accounting conclusion or proof that capitalization is required. Delivered statuses, object grants, and the source-to-FA path require tenant validation before production use.

## Planned stage

- **Procurement (Procure):** PO and receipt facts — not yet implemented
