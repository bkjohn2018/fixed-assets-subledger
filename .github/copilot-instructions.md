## CapEx Lifecycle Analytics — AI coding assistant instructions

Purpose: short, actionable guidance to help an AI agent be immediately productive in this repository.

1) Big picture (what this repo implements)
- Platform: **Capital Expenditure Lifecycle (CapEx Lifecycle)** — see `docs/conceptual/capex-lifecycle.md`.
- Domain process: **Procure-to-Capitalize (P2C)** — Procure → Pay → Collect → Capitalize. See `docs/conceptual/procure-to-capitalize.md`.
- Source: Oracle Fusion (OTBI / BI Publisher today; BICC later) → CSV extracts.
- Storage / model: contracts-first star schema (facts in `F_*`, conformed dimensions) consumed by Power BI.
- Key folders:
  - `contracts/<domain>/` — canonical column contracts (YAML). Source of truth.
  - `sql/bip/<domain>/` — BI Publisher SQL templates used to export CSVs.
  - `sql/<domain>/` — layered SQL (AP active; FA has ddl/views).
  - `powerbi/queries/<domain>/` — Power BI queries (`.m`) and `model.json`.
  - `docs/domains/<domain>/` — bus matrix and domain docs.
  - `docs/platform/` — shared standards, lineage, change discipline.
  - `scripts/` — lightweight local validation checks.
- Explicit boundary: portable query/model workspace, not an application repo. Do not add API backends, OAuth/JWT services, deployment configs, databases, generated caches, local exports, or secrets.

2) Core conventions the agent must follow
- Contracts-first: always update `contracts/<domain>/*.yml` first. CI validates via `scripts/validate_contracts.py`.
- Contract schema (required keys): `name`, `grain`, `primary_key`, `columns`, `version`.
- Active P2C domains: `fa` (Capitalize), `ap` (Pay), `projects` (Collect). Planned: `procurement`.
- FA transaction grain: `sql/bip/fa/fa_transactions_distribution.sql` is canonical for `F_Asset_Transaction`.
- FA header summary: `sql/bip/fa/fa_transactions_header.sql` omits `CODE_COMBINATION_ID`; not for COA analysis.
- AP aging: schedule grain is canonical; do not join schedules to distributions and sum `AMOUNT_REMAINING`.
- Projects grains: `F_Project_Cost` = `EXPENDITURE_ITEM_ID` + `LINE_NUM`; `F_Project_Asset_Line` = `PROJECT_ASSET_LINE_ID`; `B_Project_Cost_To_Asset_Line` = `PROJ_ASSET_LINE_DTL_UNIQ_ID` + `PROJECT_ASSET_LINE_ID`; `F_Project_Capitalization_Status` = `PROJECT_ASSET_LINE_ID` + `AS_OF_DATE`.
- Projects split warning: the lineage bridge is non-additive and one source cost can fan out to multiple asset lines. Never sum repeated source cost through the bridge; aggregate measures from their owning facts.
- Projects snapshot rule: filter to one `AS_OF_DATE` before aggregating status amounts.
- Candidate governance: candidate and policy-review flags route records to human review. They are not accounting conclusions, error assertions, or authorization to capitalize.
- COA join: `CODE_COMBINATION_ID` is the canonical key to `D_COA`.

3) Developer workflows and useful commands
- Validate contracts: `python .\scripts\validate_contracts.py`
- Check required docs: `python .\scripts\check_docs.py`
- Typical edit flow:
  1. Update `contracts/<domain>/<table>.yml`
  2. Update `sql/bip/<domain>/<...>.sql`
  3. Update `powerbi/queries/<domain>/*.m` and `powerbi/model.json`
  4. Run validation scripts

4) Files & examples to check when making changes
- FA: `contracts/fa/`, `sql/bip/fa/`, `powerbi/queries/fa/`, `docs/domains/fa/bus-matrix.md`
- AP: `contracts/ap/`, `sql/bip/ap/`, `sql/ap/`, `powerbi/queries/ap/`, `docs/domains/ap/bus-matrix.md`
- Projects: `contracts/projects/`, `sql/bip/projects/`, `sql/projects/`, `powerbi/queries/projects/`, `docs/domains/projects/bus-matrix.md`
- Platform: `docs/platform/change-discipline.md`, `docs/platform/data-lineage.md`

5) Integration & external dependencies
- Upstream: Oracle Fusion Cloud (OTBI/BICC). Exports are CSVs named per-contract conventions.
- Downstream: Power BI consumes CSVs using queries in `powerbi/queries/<domain>/`.
- Power BI project: `powerbi/CapExLifecycle.pbip`

6) Guidance for automated edits by an AI
- Preserve contract structure and keys; do not remove `primary_key` or `grain` fields.
- When renaming CSV targets, update contracts, SQL, and `.m` queries together.
- Small, verifiable changes preferred: run validation scripts after edits.

7) Release & versioning notes
- Anchored on Oracle release **26B**. Update contracts first, then SQL, then Power BI.
