# Fixed Assets Subledger (Oracle Fusion 25C)

## Purpose
Subledger-only star schema for Oracle Fusion **Fixed Assets** (25C). Source = BI Publisher (OTBI) → CSV → Power BI today; later pivot to BICC → Fabric with the same column contracts.

- Scope: Fixed Assets subledger only (no SLA).
- COA Join: `CODE_COMBINATION_ID` into governed COA.
- Use Cases: rollforwards, depreciation, additions/retirements, account-level analytics.

## Data Flow
```

Fusion OTBI (BIP Logical SQL) → CSV files → Power BI
Later: Fusion BICC (PVO extracts) → Fabric Lakehouse → same model

```

## Facts & Dimensions
**Facts**
- **F_Asset_Transaction** (header grain; can switch to distribution grain)
  - Keys: TRANSACTION_HEADER_ID, ASSET_ID, BOOK_TYPE_CODE, TRX_DATE, CODE_COMBINATION_ID
  - Measures: COST_DELTA, DEPRN_RESERVE_DELTA, PROCEEDS, GAIN_LOSS, UNITS_DELTA
- **F_Depreciation_Period** (asset×book×period)
  - Keys: ASSET_ID, BOOK_TYPE_CODE, PERIOD_COUNTER
  - Measures: DEPRN_AMOUNT, DEPRN_BONUS, DEPRN_CATCHUP, DEPRN_YTD, DEPRN_ITD
- **F_Asset_Balance_Period** (asset×book×period snapshot)
  - Keys: ASSET_ID, BOOK_TYPE_CODE, PERIOD_COUNTER
  - Measures: COST_BEG, ADDITIONS, ADJUSTMENTS, TRANSFERS_NET, RETIREMENTS_COST, DEPRN_PERIOD, DEPRN_YTD, DEPRN_ITD, NBV_END, UNITS

**Dimensions**: D_Asset (FA_ADDITIONS_B), D_Book (FA_BOOKS), D_Category, D_Location, D_Time (with FA calendar map), **D_COA (PK = CODE_COMBINATION_ID)**.

### Transaction Grain Toggle
This repo ships **both** variants. Pick one for your model:

- **Header grain (default):** `sql/bip/fa_transactions_header.sql`, contract `contracts/fa_transactions.yml`, file `fa_transactions_{yyyymm}.csv`.
  - Pros: fewer rows, fast. Cons: if a single transaction splits across accounts, you lose distribution detail.
- **Distribution grain:** `sql/bip/fa_transactions_distribution.sql`, contract `contracts/fa_transactions_distribution.yml`, file `fa_transactions_distribution_{yyyymm}.csv`.
  - Pros: exact account splits per transaction via `CODE_COMBINATION_ID`. Cons: more rows.
- **Keys:** Header PK = `TRANSACTION_HEADER_ID`. Distribution PK = `[TRANSACTION_HEADER_ID, CODE_COMBINATION_ID]` (plus `DISTRIBUTION_LINE_NUMBER` for traceability).

> In Power BI, use one or the other as `F_Asset_Transaction`. Relationships remain the same (COA by `CODE_COMBINATION_ID`).

## ERD (Mermaid)
```mermaid
erDiagram
  D_COA ||--o{ F_Asset_Transaction : has
  D_Asset ||--o{ F_Asset_Transaction : has
  D_Book ||--o{ F_Asset_Transaction : has
  D_Time ||--o{ F_Asset_Transaction : has

  D_Asset ||--o{ F_Depreciation_Period : has
  D_Book  ||--o{ F_Depreciation_Period : has
  D_Time  ||--o{ F_Depreciation_Period : has

  D_Asset ||--o{ F_Asset_Balance_Period : has
  D_Book  ||--o{ F_Asset_Balance_Period : has
  D_Time  ||--o{ F_Asset_Balance_Period : has

  F_Asset_Transaction {
    NUMBER TRANSACTION_HEADER_ID PK
    VARCHAR TRANSACTION_TYPE_CODE
    DATE TRX_DATE
    NUMBER ASSET_ID FK
    VARCHAR ASSET_NUMBER
    VARCHAR BOOK_TYPE_CODE FK
    NUMBER CODE_COMBINATION_ID FK
    NUMBER COST_DELTA
    NUMBER DEPRN_RESERVE_DELTA
    NUMBER PROCEEDS
    NUMBER GAIN_LOSS
    NUMBER UNITS_DELTA
  }

  F_Depreciation_Period {
    NUMBER ASSET_ID FK
    VARCHAR BOOK_TYPE_CODE FK
    NUMBER PERIOD_COUNTER
    VARCHAR PERIOD_NAME
    NUMBER DEPRN_AMOUNT
    NUMBER DEPRN_BONUS
    NUMBER DEPRN_CATCHUP
    NUMBER DEPRN_YTD
    NUMBER DEPRN_ITD
  }

  F_Asset_Balance_Period {
    NUMBER ASSET_ID FK
    VARCHAR BOOK_TYPE_CODE FK
    NUMBER PERIOD_COUNTER
    VARCHAR PERIOD_NAME
    NUMBER COST_BEG
    NUMBER ADDITIONS
    NUMBER ADJUSTMENTS
    NUMBER TRANSFERS_NET
    NUMBER RETIREMENTS_COST
    NUMBER DEPRN_PERIOD
    NUMBER DEPRN_YTD
    NUMBER DEPRN_ITD
    NUMBER NBV_END
    NUMBER UNITS
  }

  D_COA {
    NUMBER CODE_COMBINATION_ID PK
    -- Additional COA attributes/hierarchies live in your governed model
  }
```

## Contracts-first
Column names/types live in `contracts/*.yml` and are the source of truth. Update contracts → SQL → PBI (in that order). CI validates contracts.

## Getting Started
1) Use `sql/bip/*` in BI Publisher to export CSV partitions.
2) Point `powerbi/queries/*.m` at your CSV folder.
3) Set relationships:  
   - `F_Asset_Transaction[CODE_COMBINATION_ID] → D_COA[CODE_COMBINATION_ID]`  
   - Role-play Time: TRX_DATE vs PERIOD_COUNTER (use `USERELATIONSHIP` in measures).
4) Sanity checks: rollforward math + COA tie-out for a sample month.

## Release Discipline
- Anchored on **25C**. On quarterly updates (25D/26A…), diff What's New, update contracts first.

License: MIT (or org standard).