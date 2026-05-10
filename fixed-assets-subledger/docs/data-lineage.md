# Data Lineage
Oracle Fixed Assets ESS reporting extract → OTBI (BIP Logical SQL) → CSV partitions → Power BI model
Later: BICC PVOs → Fabric Lakehouse → same star schema

Oracle 26B documents the Fixed Assets OTBI subject areas as extract-backed:
- `Fixed Assets - Asset Transactions Real Time`: distribution-line grain via `FA_TRX_EXTRACT`
- `Fixed Assets - Asset Depreciation Real Time`: depreciation-distribution grain via `FA_DEPRN_EXTRACT`
- `Fixed Assets - Asset Balances Real Time`: transaction-distribution-line grain via `FA_BALANCES_EXTRACT`
