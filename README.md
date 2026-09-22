# Capital Expenditure Lifecycle Analytics

Portable query, contract, and Power BI model artifacts for Oracle Fusion **CapEx Lifecycle** capital investment analytics.

**Boardroom:** Capital Expenditure Lifecycle (CapEx Lifecycle)  
**Domain process:** [Procure-to-Capitalize (P2C)](docs/conceptual/procure-to-capitalize.md) — Procure → Pay → Collect → Capitalize

This repository stores source-controlled analytics artifacts only: Oracle OTBI/BIP logical SQL, column contracts, Power BI query/model definitions, documentation, and lightweight validation scripts.

Platform conceptual model: [`docs/conceptual/capex-lifecycle.md`](docs/conceptual/capex-lifecycle.md)

[Oracle Financials 26B Tables and Views](https://docs.oracle.com/en/cloud/saas/financials/26b/oedmf/index.html)

## Domain registry

| CapEx stage | P2C stage | Domain | Status | Bus matrix |
|-------------|-----------|--------|--------|------------|
| Commitment | Procure | Procurement | Planned | — |
| Spend & payables | Pay | AP | Active | [`docs/domains/ap/bus-matrix.md`](docs/domains/ap/bus-matrix.md) |
| Cost collection | Collect | Projects | Active | [`docs/domains/projects/bus-matrix.md`](docs/domains/projects/bus-matrix.md) |
| In-service assets | Capitalize | Fixed Assets | Active | [`docs/domains/fa/bus-matrix.md`](docs/domains/fa/bus-matrix.md) |

## Scope

In scope:

- CapEx Lifecycle analytics on Oracle Fusion (FA, AP, and Projects active; Procurement planned)
- OTBI / BI Publisher extract SQL under `sql/bip/<domain>/`
- Column contracts under `contracts/<domain>/`
- Power BI query and model metadata under `powerbi/`
- Documentation under `docs/conceptual/`, `docs/domains/`, `docs/platform/`
- Lightweight validation scripts under `scripts/`

Out of scope:

- Application backends, API services, databases, OAuth/JWT code, and deployment configs
- Local data exports, `.pbix` files, generated caches, virtual environments, and secrets
- Machine-specific editor settings

## Source pattern

Current flow:

```text
Oracle extract (ESS / base tables)
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

## Model grain

The model is contracts-first. Update the contract before changing SQL or Power BI metadata.

| Fact | P2C stage | Grain | Primary key |
| --- | --- | --- | --- |
| `F_Asset_Transaction` | Capitalize | Transaction distribution line | `TRANSACTION_HEADER_ID`, `DISTRIBUTION_LINE_NUMBER` |
| `F_Depreciation_Period` | Capitalize | Asset × book × period | `ASSET_ID`, `BOOK_TYPE_CODE`, `PERIOD_COUNTER` |
| `F_Asset_Balance_Period` | Capitalize | Asset × book × period snapshot | `ASSET_ID`, `BOOK_TYPE_CODE`, `PERIOD_COUNTER` |
| `F_AP_Aging_Schedule` | Pay | Payment schedule × as-of date | `INVOICE_ID`, `PAYMENT_NUM`, `AS_OF_DATE` |
| `F_AP_Invoice_Distribution` | Pay | Invoice distribution line | `INVOICE_DISTRIBUTION_ID` |
| `Supplier_History` | Pay | Invoice distribution accounting event | `INVOICE_DISTRIBUTION_ID`, `AE_HEADER_ID` |
| `F_Project_Cost` | Collect | Project cost distribution line | `EXPENDITURE_ITEM_ID`, `LINE_NUM` |
| `F_Project_Asset_Line` | Collect | Project asset line | `PROJECT_ASSET_LINE_ID` |
| `B_Project_Cost_To_Asset_Line` | Collect | Expanded project asset line detail lineage link | `PROJ_ASSET_LINE_DTL_UNIQ_ID`, `PROJECT_ASSET_LINE_ID` |
| `F_Project_Capitalization_Status` | Collect | Project asset line × as-of date snapshot | `PROJECT_ASSET_LINE_ID`, `AS_OF_DATE` |

`CODE_COMBINATION_ID` is the canonical COA key for account-level analysis.

## Domain quick reference

### Fixed Assets (Capitalize)

- Contracts: `contracts/fa/`
- BIP: `sql/bip/fa/`
- DDL / views: `sql/fa/ddl/`, `sql/fa/views/`
- Power Query: `powerbi/queries/fa/`
- Bus matrix: `docs/domains/fa/bus-matrix.md`

Canonical transaction extract: `sql/bip/fa/fa_transactions_distribution.sql` → `F_Asset_Transaction`

### Accounts Payable (Pay)

- Contracts: `contracts/ap/`
- Layered SQL: `sql/ap/`
- BIP: `sql/bip/ap/`
- Power Query: `powerbi/queries/ap/`
- Bus matrix: `docs/domains/ap/bus-matrix.md`
- Report pages: `docs/domains/ap/ap-aging-report-pages.md`

**Grain rule:** Do not join payment schedules to distributions and sum `AMOUNT_REMAINING`. Use the invoice-level bridge on the aging fact or drill through `F_AP_Invoice_Distribution`.

### Projects (Collect)

- Contracts: `contracts/projects/`
- Layered SQL: `sql/projects/`
- BIP: `sql/bip/projects/`
- Power Query: `powerbi/queries/projects/`
- Bus matrix: `docs/domains/projects/bus-matrix.md`

Traceability follows project cost distribution → lineage bridge → project asset line → capitalization status → posted FA asset. The bridge is non-additive: split asset lines can repeat a source cost after a join. Candidate flags identify items for governed review; they are not accounting conclusions or authorization to capitalize.

## Repository layout

```text
contracts/<domain>/     Column contracts and grain declarations
docs/
  conceptual/           CapEx Lifecycle + P2C process model
  domains/<domain>/     Bus matrix and domain docs
  platform/             Shared standards, lineage, ERD
  glossary/             CapEx and P2C terms
powerbi/                Semantic model, measures, M queries by domain
scripts/                Validation scripts
sql/
  bip/<domain>/         BI Publisher / OTBI logical SQL extracts
  ap/                   AP layered SQL (staging, marts, diagnostics)
  fa/                   FA DDL and views
```

## Workflow

1. Run Oracle extract prerequisites (FA ESS process for OTBI subject areas).
2. Export CSV partitions using SQL in `sql/bip/<domain>/`.
3. Load CSVs through Power Query in `powerbi/queries/<domain>/`.
4. Validate relationships and reconcile a sample period per domain.

See [`docs/platform/change-discipline.md`](docs/platform/change-discipline.md) for the full change order.

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

## Power BI notes

The checked-in Power BI files are source artifacts, not packaged report files.

- Open **`powerbi/CapExLifecycle.pbip`** in Power BI Desktop (enable **Preview**: *Power BI Project (.pbip) save option*) to edit the semantic model (`CapExLifecycle.SemanticModel`) and report (`CapExLifecycle.Report`).
- AP Aging report pages (scaffold): Executive Aging Overview, Operational Resolution Queue, Financial / Project Impact — see [`docs/domains/ap/ap-aging-report-pages.md`](docs/domains/ap/ap-aging-report-pages.md).
- Facts and conforming dimensions ship as **typed empty tables** wired like `powerbi/model.json`; replace each partition M with the CSV loaders in `powerbi/queries/<domain>/`, apply `powerbi/measures.dax`, then reconcile.
- `.pbix` files and CSV exports are intentionally ignored.

## Release discipline

Current source baseline: Oracle Fusion Financials 26B.

On quarterly updates: review Oracle release notes per active domain, update contracts first, then SQL and Power BI metadata, then re-run validations.

## References

- [Oracle Financials 26B Tables and Views](https://docs.oracle.com/en/cloud/saas/financials/26b/oedmf/index.html)
- [Oracle Financials 26B OTBI Subject Areas](https://docs.oracle.com/en/cloud/saas/financials/26b/faofb/subject-areas-for-transactional-business-intelligence-in-financials.pdf)
- [Oracle Financials 26B Books](https://docs.oracle.com/en/cloud/saas/financials/26b/books.html)
