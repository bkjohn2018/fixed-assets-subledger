# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Capital Expenditure Lifecycle (CapEx Lifecycle) analytics for Oracle Fusion. This is a **portable query/model workspace, not an application repo**: Oracle OTBI/BI Publisher logical SQL, column contracts, Power BI query/model definitions, and documentation. There is no application backend, API, database, or deployment config here — do not add any.

Domain process: Procure-to-Capitalize (P2C) — Procure → Pay → Collect → Capitalize. Three domains are active today:

- **Fixed Assets (`fa`)** — Capitalize stage
- **Accounts Payable (`ap`)** — Pay stage
- **Projects (`projects`)** — Collect stage

Procurement (Procure stage) is planned but not yet implemented.

Source baseline: **Oracle Fusion Financials 26B**.

## Commands

Run from the repository root.

```powershell
python scripts\validate_contracts.py   # validates every contracts/**/*.yml has name, grain, primary_key, columns, version
python scripts\check_docs.py           # verifies required docs (README, conceptual docs, domain bus matrices, platform docs) exist
sqlfluff lint sql --dialect oracle     # optional SQL lint (SQLFluff config: .sqlfluff, max_line_length=120)
```

These three are exactly what CI (`.github/workflows/ci.yml`) runs on every push/PR. There is no build step and no test suite beyond these validators — a change is "passing" when both Python scripts exit 0 and sqlfluff is clean.

## Architecture: contracts-first star schema

The model is **contracts-first**: `contracts/<domain>/*.yml` is the source of truth. Never edit SQL or Power BI metadata without updating the contract first.

**The change order (see `docs/platform/change-discipline.md`) is mandatory and must be followed in sequence:**

1. Update `contracts/<domain>/<table>.yml` (required keys: `name`, `grain`, `primary_key`, `columns`, `version`)
2. Update matching `sql/bip/<domain>/*.sql` (the BI Publisher/OTBI extract SQL)
3. Update `sql/<domain>/` layered SQL if applicable (AP has staging/intermediate/marts/diagnostics layers; FA has ddl/views)
4. Update `powerbi/queries/<domain>/*.m` and `powerbi/model.json`
5. Update the domain bus matrix (`docs/domains/<domain>/bus-matrix.md`) and lineage docs if grain or source assumptions changed
6. Run `validate_contracts.py` and `check_docs.py`

### Data flow

```
Oracle extract (ESS reporting job) -> OTBI / BI Publisher logical SQL -> CSV partitions -> Power BI model
```

A future flow (Oracle BICC/PVO → Fabric Lakehouse) is planned but not implemented; keep the contract-driven model compatible with it.

### Naming conventions (`docs/platform/naming-standards.md`)

- Facts: `F_<Domain>_<Process>`, e.g. `F_Asset_Transaction`, `F_AP_Aging_Schedule`. One grain per fact, documented in the contract's `grain` field and the bus matrix.
- Dimensions: `D_<Concept>`, e.g. `D_Asset`, `D_COA`, `D_Supplier` — conformed across P2C stages (see `docs/platform/conformed-dimensions.md`). `CODE_COMBINATION_ID` is the canonical chart-of-accounts join key.
- Bridges: `B_<From>_To_<To>`, or invoice-level bridge columns on a fact when grains differ. Bridge columns are non-additive with fact measures at the finer grain.
- CSV export naming follows the contract base name plus a date suffix (`{contract_base}_{yyyymm}.csv` or `..._{yyyymmdd}.csv`).

### Grain guardrails — do not violate

- Never mix grains in one fact.
- **AP aging:** the payment-schedule grain is canonical for `F_AP_Aging_Schedule`. Do not join payment schedules to distributions and sum `AMOUNT_REMAINING` — use the invoice-level bridge on the aging fact, or drill through `F_AP_Invoice_Distribution` instead.
- **FA transactions:** `sql/bip/fa/fa_transactions_distribution.sql` is the canonical extract for `F_Asset_Transaction` (transaction distribution line grain). `sql/bip/fa/fa_transactions_header.sql` is a convenience header-level summary that omits `CODE_COMBINATION_ID` — it is not valid for COA-level analysis and must stay clearly secondary to the distribution-grain fact.
- **Projects costs:** `F_Project_Cost` stays at `EXPENDITURE_ITEM_ID` + `LINE_NUM`; `F_Project_Asset_Line` stays at `PROJECT_ASSET_LINE_ID`; `F_Project_Capitalization_Status` stays at `PROJECT_ASSET_LINE_ID` + `AS_OF_DATE`.
- **Projects lineage bridge:** `B_Project_Cost_To_Asset_Line` stays at `PROJ_ASSET_LINE_DTL_UNIQ_ID` + `PROJECT_ASSET_LINE_ID` and is non-additive. A split can copy the source detail to multiple asset lines, so joining through the bridge repeats source cost. Keep amounts on their owning facts and count distinct lineage keys.
- **Projects snapshots:** select one `AS_OF_DATE` before aggregating status amounts. Do not add source cost, assigned asset-line cost, and posted FA amount as independent balances.
- **Candidate governance:** `IS_CAPITALIZATION_CANDIDATE` and `POLICY_REVIEW_REQUIRED` are human-review signals based on Oracle eligibility, aging, holds, and posted evidence. They are not accounting conclusions, error assertions, or authorization to capitalize.
- Cross-stage P2C links (e.g. Pay → Capitalize) use bridges and conformed keys, not blended rows.

### Per-domain layout

| Domain | Contracts | BIP extract SQL | Other SQL | Power Query | Bus matrix |
|---|---|---|---|---|---|
| FA (Capitalize) | `contracts/fa/` | `sql/bip/fa/` | `sql/fa/ddl/`, `sql/fa/views/` | `powerbi/queries/fa/` | `docs/domains/fa/bus-matrix.md` |
| AP (Pay) | `contracts/ap/` | `sql/bip/ap/` | `sql/ap/{staging,intermediate,marts,diagnostics}/` | `powerbi/queries/ap/` | `docs/domains/ap/bus-matrix.md`, `docs/domains/ap/ap-aging-report-pages.md` |
| Projects (Collect) | `contracts/projects/` | `sql/bip/projects/` | `sql/projects/{staging,intermediate,marts,diagnostics}/` | `powerbi/queries/projects/` | `docs/domains/projects/bus-matrix.md` |

Fact grains (also in README):

| Fact | Grain | Primary key |
|---|---|---|
| `F_Asset_Transaction` | Transaction distribution line | `TRANSACTION_HEADER_ID`, `DISTRIBUTION_LINE_NUMBER` |
| `F_Depreciation_Period` | Asset × book × period | `ASSET_ID`, `BOOK_TYPE_CODE`, `PERIOD_COUNTER` |
| `F_Asset_Balance_Period` | Asset × book × period snapshot | `ASSET_ID`, `BOOK_TYPE_CODE`, `PERIOD_COUNTER` |
| `F_AP_Aging_Schedule` | Payment schedule × as-of date | `INVOICE_ID`, `PAYMENT_NUM`, `AS_OF_DATE` |
| `F_AP_Invoice_Distribution` | Invoice distribution line | `INVOICE_DISTRIBUTION_ID` |
| `F_Project_Cost` | Project cost distribution line | `EXPENDITURE_ITEM_ID`, `LINE_NUM` |
| `F_Project_Asset_Line` | Project asset line | `PROJECT_ASSET_LINE_ID` |
| `B_Project_Cost_To_Asset_Line` | Expanded project asset line detail lineage link | `PROJ_ASSET_LINE_DTL_UNIQ_ID`, `PROJECT_ASSET_LINE_ID` |
| `F_Project_Capitalization_Status` | Project asset line × as-of date snapshot | `PROJECT_ASSET_LINE_ID`, `AS_OF_DATE` |

### Docs structure

- `docs/conceptual/` — CapEx Lifecycle and P2C process model (`capex-lifecycle.md`, `procure-to-capitalize.md`)
- `docs/domains/<domain>/` — bus matrix and domain-specific docs
- `docs/platform/` — shared cross-domain standards: `change-discipline.md`, `naming-standards.md`, `conformed-dimensions.md`, `data-lineage.md`, `ERD.md`, `bus-matrix-template.md`
- `docs/glossary/` — CapEx and P2C terminology

### Adding a new P2C domain (e.g. Procurement)

Checklist from `docs/platform/change-discipline.md`:

1. Add a row to the domain registry in README and `docs/conceptual/capex-lifecycle.md`
2. Copy `docs/platform/bus-matrix-template.md` to `docs/domains/<domain>/bus-matrix.md`
3. Add contracts under `contracts/<domain>/`
4. Add BIP extract SQL and any layered SQL
5. Extend the required-docs list in `scripts/check_docs.py` once the domain goes active

## Power BI

`powerbi/CapExLifecycle.pbip` is the Power BI Project source (open in Power BI Desktop with the *Power BI Project (.pbip) save option* preview enabled) — edits go through `CapExLifecycle.SemanticModel` and `CapExLifecycle.Report`, not through committing `.pbix`/CSV artifacts (both are gitignored). Facts and conformed dimensions ship as typed empty tables; partition M queries in `powerbi/queries/<domain>/` are the CSV loaders, and `powerbi/measures.dax` holds the DAX measures layer.

## Out of scope

Do not add: application backends, API services, OAuth/JWT code, deployment configs, databases, local data exports, `.pbix` files, generated caches, virtual environments, secrets, or machine-specific editor settings.
