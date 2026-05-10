# Fixed Assets Subledger

Portable query, contract, and Power BI model artifacts for an Oracle Fusion Fixed Assets subledger model.

This repository is designed to move cleanly between a personal development machine and a work machine. It stores source-controlled analytics artifacts only: Oracle OTBI/BIP logical SQL, column contracts, Power BI query/model definitions, documentation, and lightweight validation scripts.

[Oracle Financials 26B Tables and Views](https://docs.oracle.com/en/cloud/saas/financials/26b/oedmf/index.html)

## Scope

In scope:

- Oracle Fusion Fixed Assets subledger reporting
- OTBI / BI Publisher extract SQL under `sql/bip/`
- Column contracts under `contracts/`
- Power BI query and model metadata under `powerbi/`
- Data lineage and bus matrix documentation under `docs/`
- Simple validation scripts under `scripts/`

Out of scope:

- SLA, GL, AP, Projects, or lease accounting facts unless added as separate future domains
- Application backends, API services, databases, OAuth/JWT code, and deployment configs
- Local data exports, `.pbix` files, generated caches, virtual environments, and secrets
- Machine-specific editor settings

## Source Pattern

Current flow:

```text
Oracle Fixed Assets reporting extract ESS process
  -> OTBI / BI Publisher logical SQL
  -> CSV partitions
  -> Power BI model
```

Future flow:

```text
Oracle BICC / PVO extracts
  -> Fabric Lakehouse
  -> same contract-driven model
```

Before exporting Fixed Assets OTBI subject areas, run Oracle's Fixed Assets reporting extract ESS process so the reporting extract tables are current.

Oracle 26B documents the relevant OTBI subject areas as extract-backed:

- `Fixed Assets - Asset Transactions Real Time`: distribution-line grain via `FA_TRX_EXTRACT`
- `Fixed Assets - Asset Depreciation Real Time`: depreciation-distribution grain via `FA_DEPRN_EXTRACT`
- `Fixed Assets - Asset Balances Real Time`: transaction-distribution-line grain via `FA_BALANCES_EXTRACT`

## Model Grain

The model is contracts-first. Update the contract before changing SQL or Power BI metadata.

| Fact | Grain | Primary key |
| --- | --- | --- |
| `F_Asset_Transaction` | Transaction distribution line | `TRANSACTION_HEADER_ID`, `DISTRIBUTION_LINE_NUMBER` |
| `F_Depreciation_Period` | Asset x book x period, aggregated from OTBI distribution rows | `ASSET_ID`, `BOOK_TYPE_CODE`, `PERIOD_COUNTER` |
| `F_Asset_Balance_Period` | Asset x book x period snapshot, aggregated from OTBI distribution rows | `ASSET_ID`, `BOOK_TYPE_CODE`, `PERIOD_COUNTER` |

`CODE_COMBINATION_ID` is the canonical COA key for account-level analysis.

## Transaction Extracts

Canonical transaction extract:

- SQL: `sql/bip/fa_transactions_distribution.sql`
- Contracts: `contracts/fa_transactions.yml`, `contracts/fa_transactions_distribution.yml`
- CSV pattern: `fa_transactions_distribution_{yyyymm}.csv`
- Use this as `F_Asset_Transaction` in Power BI.

Convenience header summary:

- SQL: `sql/bip/fa_transactions_header.sql`
- CSV pattern: `fa_transactions_header_{yyyymm}.csv`
- Use only when account-level analysis is not needed.
- This query groups distribution rows to transaction header and intentionally omits `CODE_COMBINATION_ID`.

## Repository Layout

```text
contracts/             Column contracts and grain declarations
docs/                  Bus matrix, ERD notes, and lineage
powerbi/               Power BI model metadata, measures, and M queries
scripts/               Lightweight validation scripts
sql/bip/               BI Publisher / OTBI logical SQL extracts
sql/ddl/               External table staging DDL
sql/views/             Convenience views, not authoritative contracts
```

## Workflow

1. Run Oracle's Fixed Assets reporting extract ESS process.
2. Export CSV partitions using the SQL in `sql/bip/`.
3. Load the CSVs through the Power BI queries in `powerbi/queries/`.
4. Validate relationships:
   - `F_Asset_Transaction[CODE_COMBINATION_ID]` to `D_COA[CODE_COMBINATION_ID]`
   - `F_Asset_Transaction[TRX_DATE]` to date role in `D_Time`
   - Period facts through `PERIOD_COUNTER`
5. Reconcile a sample month:
   - transaction additions / retirements
   - depreciation period amount
   - net book value rollforward
   - COA tie-out where account-level data is expected

## Change Discipline

For column, grain, or naming changes:

1. Update `contracts/*.yml`.
2. Update the matching `sql/bip/*.sql`.
3. Update `powerbi/queries/*.m` and `powerbi/model.json`.
4. Update docs if the business grain or source assumption changed.
5. Run validations.

Avoid mixing grains in one fact. If a reporting need requires both distribution and header views, keep one canonical fact and one clearly named aggregate or convenience extract.

## Validation

From the repository root:

```powershell
python scripts\check_docs.py
python scripts\validate_contracts.py
```

Optional SQL linting, if SQLFluff is installed:

```powershell
sqlfluff lint sql --dialect oracle
```

## Power BI Notes

The checked-in Power BI files are source artifacts, not packaged report files.

- Open **`powerbi/FixedAssetsSubledger.pbip`** in Power BI Desktop (enable **Preview**: *Power BI Project (.pbip) save option*) to edit the scaffolded semantic model (`FixedAssetsSubledger.SemanticModel`) and report (`FixedAssetsSubledger.Report`).
- Facts and conforming dimensions ship as **typed empty tables** wired like `powerbi/model.json`; replace each partition M with the CSV loaders in `powerbi/queries/`, apply `powerbi/measures.dax`, then reconcile using the checklist in **Workflow**.
- `.pbix` files are intentionally ignored.
- CSV exports are intentionally ignored.
- The `.m` files in `powerbi/queries/` are Power Query files, even though GitHub may classify `.m` as another language.

## Release Discipline

Current source baseline: Oracle Fusion Financials 26B.

On quarterly updates:

1. Review Oracle What's New, OEDMF, and OTBI subject-area documentation.
2. Confirm subject-area grain and extract prerequisites.
3. Update contracts first.
4. Update SQL and Power BI metadata.
5. Re-run validations and a sample reconciliation.

## References

- [Oracle Financials 26B Tables and Views](https://docs.oracle.com/en/cloud/saas/financials/26b/oedmf/index.html)
- [Oracle Financials 26B OTBI Subject Areas](https://docs.oracle.com/en/cloud/saas/financials/26b/faofb/subject-areas-for-transactional-business-intelligence-in-financials.pdf)
- [Oracle Financials 26B Books](https://docs.oracle.com/en/cloud/saas/financials/26b/books.html)
