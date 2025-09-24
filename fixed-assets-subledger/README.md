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

## ERD (ASCII)
```

D\_COA (CODE\_COMBINATION\_ID) <— F\_Asset\_Transaction —> D\_Asset, D\_Book, D\_Time(TRX\_DATE)

F\_Depreciation\_Period —> D\_Asset, D\_Book, D\_Time(PERIOD\_COUNTER)
F\_Asset\_Balance\_Period —> D\_Asset, D\_Book, D\_Time(PERIOD\_COUNTER)

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