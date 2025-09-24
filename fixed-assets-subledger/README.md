# Fixed Assets Subledger (Oracle Fusion 25C)

## Purpose

This project delivers a **subledger-only star schema** for Oracle Fusion **Fixed Assets** (25C release).

It extracts **flat files** from BI Publisher (OTBI subject areas) and stages them for analytics in **Power BI** today, with a clean migration path to **BICC → Fabric** later.

* **Scope**: Oracle Fusion Assets subledger only (no SLA staging).
* **Join to GL**: via `CODE_COMBINATION_ID` into your governed COA model.
* **Use case**: depreciation, rollforwards, additions/retirements, account-level reconciliations.

---

## Data Flow

```
Fusion OTBI (BIP Logical SQL) → Flat Files (CSV) → Repo Staging (sql/ddl external tables optional) → Power BI

Later: Fusion BICC (PVO Extracts) → Fabric Lakehouse → Same model
```

---

## Facts & Dimensions

### Facts

* **F\_Asset\_Transaction**
  Grain = transaction header (or distribution if enabled)
  Keys: TRANSACTION\_HEADER\_ID, ASSET\_ID, BOOK\_TYPE\_CODE, TRX\_DATE, CODE\_COMBINATION\_ID
  Measures: COST\_DELTA, DEPRN\_RESERVE\_DELTA, PROCEEDS, GAIN\_LOSS, UNITS\_DELTA

* **F\_Depreciation\_Period**
  Grain = asset × book × period
  Keys: ASSET\_ID, BOOK\_TYPE\_CODE, PERIOD\_COUNTER
  Measures: DEPRN\_AMOUNT, DEPRN\_BONUS, DEPRN\_CATCHUP, DEPRN\_YTD, DEPRN\_ITD

* **F\_Asset\_Balance\_Period**
  Grain = asset × book × period (snapshot)
  Keys: ASSET\_ID, BOOK\_TYPE\_CODE, PERIOD\_COUNTER
  Measures: COST\_BEG, ADDITIONS, ADJUSTMENTS, TRANSFERS\_NET, RETIREMENTS\_COST, DEPRN\_PERIOD, DEPRN\_YTD, DEPRN\_ITD, NBV\_END, UNITS

### Dimensions

* **D\_Asset** ← FA\_ADDITIONS\_B
* **D\_Book** ← FA\_BOOKS
* **D\_Category**
* **D\_Location**
* **D\_Time** (includes FA calendar/period map)
* **D\_COA** ← governed chart of accounts (PK = CODE\_COMBINATION\_ID)

---

## ERD (ASCII)

```
D_COA (CODE_COMBINATION_ID) <— F_Asset_Transaction —> D_Asset, D_Book, D_Time(TRX_DATE)

F_Depreciation_Period —> D_Asset, D_Book, D_Time(PERIOD_COUNTER)
F_Asset_Balance_Period —> D_Asset, D_Book, D_Time(PERIOD_COUNTER)
```

---

## Data Contracts

Each dataset has a YAML contract in `contracts/` describing:

* **Grain**
* **Primary Key**
* **Foreign Keys**
* **Columns + Types**
* **Refresh Cadence**
* **Release Version (25C)**

Contracts must be updated first when adding/changing columns. CI validates schema consistency.

---

## Repo Layout

```
contracts/       # YAML contracts for each fact
sql/bip/         # BI Publisher Logical SQL (OTBI extracts)
sql/ddl/         # External-table DDL stubs for CSVs
sql/views/       # Convenience/unified views
powerbi/         # Model metadata, queries (M), measures (DAX)
scripts/         # Contract validator
.github/         # Workflows (lint, validate)
docs/            # ERD, lineage
```

---

## CI & Standards

* **SQLFluff** for SQL linting (dialect=oracle).
* **Contract Validator** (Python) checks YAML completeness.
* **Pre-commit** recommended for local runs.
* **PR Workflow**: Update contract → SQL → Power BI.

---

## Getting Started

1. **Export CSVs** via BI Publisher using `sql/bip/*` queries.
2. Drop files into `data/` or configured staging path.
3. Load into Power BI using `powerbi/queries/*.m` stubs.
4. Confirm relationships:

   * `F_Asset_Transaction[CODE_COMBINATION_ID] → D_COA[CODE_COMBINATION_ID]`
   * Time role-play: TRX\_DATE vs PERIOD\_COUNTER (use USERELATIONSHIP in DAX).
5. Validate rollforwards (Cost\_Beg + Adds + Adjs + Transfers − Rets = proxy Cost\_End).

---

## Migration to Fabric

* Swap BI Publisher → BICC extracts (same column contracts).
* Land in Fabric Lakehouse.
* Repoint Power BI tables, keep the star schema unchanged.

---

## Release

* Anchored on Oracle Fusion **25C**.
* Check Oracle "What's New" each quarter (25D, 26A …).
* Update contracts + SQL as new attributes are exposed.

---

## License

MIT (or your org standard).
