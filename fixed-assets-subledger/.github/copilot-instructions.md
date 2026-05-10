## Fixed Assets Subledger — AI coding assistant instructions

Purpose: short, actionable guidance to help an AI agent be immediately productive in this repository.

1) Big picture (what this repo implements)
- Source: Oracle Fusion (OTBI / BI Publisher today; BICC later) → CSV extracts.
- Storage / model: a contracts-first star schema (facts in `F_*`, conformed dimensions) consumed by Power BI.
- Key folders:
  - `contracts/` — canonical column contracts (YAML). Source of truth.
  - `sql/bip/` — BI Publisher SQL templates used to export CSVs.
  - `powerbi/` — Power BI queries (`.m`) and `model.json` that consume CSV files.
  - `docs/` — bus matrix and lineage; authoritative design docs.
  - `scripts/` — lightweight local validation checks.
- Explicit boundary: this repo is a portable query/model workspace, not an application repo. Do not add API backends, OAuth/JWT services, deployment configs, databases, generated caches, local exports, or secrets.

2) Core conventions the agent must follow
- Contracts-first: always update `contracts/*.yml` first. The project CI (or ad-hoc checks) validates contracts via `scripts/validate_contracts.py`.
- Contract schema (required keys): `name`, `grain`, `primary_key`, `columns`, `version`. The `validate_contracts.py` script enforces this.
- Transaction grain: Oracle 26B documents `Fixed Assets - Asset Transactions Real Time` at asset transaction distribution-line grain via `FA_TRX_EXTRACT`. Treat `sql/bip/fa_transactions_distribution.sql` and `fa_transactions_distribution_{yyyymm}.csv` as canonical for `F_Asset_Transaction`.
- Header summaries: `sql/bip/fa_transactions_header.sql` is a convenience aggregate and intentionally omits `CODE_COMBINATION_ID`; do not use it for COA/account-level analysis.
- Depreciation and balances: Oracle documents the OTBI source rows at distribution grain. The repo's period-grain depreciation and balance extracts must aggregate distribution rows to `ASSET_ID`, `BOOK_TYPE_CODE`, and `PERIOD_COUNTER`.
- Oracle extract prerequisite: run the Fixed Assets reporting extract ESS process before exporting OTBI subject areas.
- COA join: `CODE_COMBINATION_ID` is the canonical key to D_COA; many relationships rely on it. See `README.md` and `sql/bip/*` for examples.

3) Developer workflows and useful commands
- Quick validations (PowerShell):
  - Validate contracts: `python .\scripts\validate_contracts.py`
  - Check required docs present: `python .\scripts\check_docs.py`
  These scripts are plain Python (3.x); no dependency files are present in repo.
- Typical edit flow for adding/removing columns:
  1. Update `contracts/<table>.yml` (add column + type).
  2. Update `sql/bip/<...>.sql` to select/emit the column for BI Publisher.
  3. Update `powerbi/queries/*.m` (or `model.json`) to reference the new column.
  4. Run `scripts/validate_contracts.py` to check the contract shape.

4) Files & examples to check when making changes
- Facts: `sql/bip/fa_balances.sql`, `sql/bip/fa_deprn_period.sql`, `sql/bip/fa_transactions_header.sql`, `sql/bip/fa_transactions_distribution.sql`.
- Contracts: `contracts/fa_balances.yml`, `contracts/fa_deprn_period.yml`, `contracts/fa_transactions.yml`, `contracts/fa_transactions_distribution.yml`.
- Power BI: `powerbi/queries/F_Asset_Transaction.m`, `powerbi/model.json`.
- Docs: `docs/bus-matrix.md`, `docs/data-lineage.md`.

5) Integration & external dependencies
- Upstream: Oracle Fusion Cloud (OTBI/BICC). Exports are CSVs named per-contract conventions (e.g. `fa_transactions_202501.csv`).
- Downstream: Power BI consumes the CSVs using the queries in `powerbi/queries/`.
- No package manager is required in the repo root; validation is handled by simple Python scripts present in `scripts/` and the GitHub workflow.

6) Guidance for automated edits by an AI
- Preserve `contracts/*.yml` structure and keys; do not remove `primary_key` or `grain` fields.
- When changing SQL, keep BI Publisher compatibility in mind (these SQLs are run by BI Publisher; avoid DB-specific extensions unless already present).
- When renaming a CSV target, update all references: SQL, contracts, and `.m` queries.
- Use explicit file references when modifying Power BI queries: search `powerbi/queries/` for the exact name.
- Small, verifiable changes preferred: after edits run the two validation scripts above and surface their stdout/exit code.

7) Release & versioning notes
- This repo is anchored on Oracle release **26B** (see `README.md`). When Oracle release changes are required, update `contracts/*.yml` first and follow the contract→SQL→PowerBI order.

If anything above is unclear or you want more examples (for instance: an example `contracts/*.yml` fragment or a walkthrough of switching transaction grain end-to-end), tell me which part to expand and I will iterate.
