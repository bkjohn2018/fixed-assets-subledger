# Projects — Kimball Bus Matrix (Oracle Fusion 26B)

Projects is the active **Collect** stage of Procure-to-Capitalize. The model preserves Oracle source grains while tracing a project cost distribution through project asset assignment and transfer to a posted Fixed Assets asset.

| Business process | Dataset / exact grain | D_Project | D_Task | D_Time | D_COA | D_Asset | Additivity |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| Project cost distribution | `F_Project_Cost` — one row per `EXPENDITURE_ITEM_ID` + `LINE_NUM` from `PJC_COST_DIST_LINES_ALL` | ✔ | ✔ | `PRVDR_GL_DATE` | ✔ | — | Raw and burdened cost are additive across unique distribution rows in a common currency and accounting basis. |
| Project asset line | `F_Project_Asset_Line` — one row per `PROJECT_ASSET_LINE_ID` from `PJC_PRJ_ASSET_LNS_ALL`, enriched with project-asset context | ✔ | ✔ when assigned | service/transfer dates | — | posted asset when known | `CURRENT_ASSET_COST` is additive only across unique asset lines in a common currency; do not combine it with source cost as though both were independent amounts. |
| Cost-to-asset-line lineage | `B_Project_Cost_To_Asset_Line` — one row per `PROJ_ASSET_LINE_DTL_UNIQ_ID` + `PROJECT_ASSET_LINE_ID`, an expanded lineage link from `PJC_PRJ_ASSET_LN_DETS` | ✔ | ✔ | — | — | — | **Non-additive.** The bridge carries lineage keys, not measures. |
| Capitalization status snapshot | `F_Project_Capitalization_Status` — one row per `PROJECT_ASSET_LINE_ID` + `AS_OF_DATE` | ✔ | ✔ when assigned | `AS_OF_DATE` | — | ✔ when posted | Snapshot amounts are additive only within one as-of date and a common currency; never sum the same line across snapshots. |

Canonical conformed natural keys are `PROJECT_ID` and `TASK_ID`. For `F_Project_Cost`, `CODE_COMBINATION_ID` is the canonical `D_COA` key sourced from `RAW_COST_DR_CCID`; it classifies `ACCT_RAW_COST`. Burdened-cost account lineage can differ and must not be inferred from this key. Posted `ASSET_ID` conforms status to `D_Asset`.

## Lifecycle statuses

`F_Project_Capitalization_Status` uses these governed workflow states:

- `POSTED_CAPITALIZED` — posted Fixed Assets evidence exists in `FA_ASSET_INVOICES`.
- `TRANSFERRED_NOT_POSTED` — transferred to the mass-additions workflow but no posted FA evidence exists as of the snapshot.
- `TRANSFER_REJECTED` — Oracle transfer or mass-addition processing records a rejection.
- `GENERATED_UNASSIGNED` — an asset line exists but assignment to a project asset is incomplete.
- `CAPITALIZABLE_NOT_GENERATED` — on `F_Project_Cost`, Oracle identifies the source cost as capitalizable, but no project asset line has been generated; a row without an asset line cannot occur in the asset-line status snapshot.
- `HELD` — an Oracle hold prevents normal capitalization processing.
- `POLICY_REVIEW_REQUIRED` — the governed aging and eligibility rules identify an unresolved item for human review.

Delivered Oracle status values and object access must be profiled in each tenant before production use.

## Candidate-review governance

`IS_CAPITALIZATION_CANDIDATE` and `POLICY_REVIEW_REQUIRED` are review-queue indicators, **not accounting conclusions, error assertions, or authorization to capitalize**. A candidate requires Oracle-recorded capitalizable status, elapsed configured grace days, no hold, and no posted FA evidence as of `AS_OF_DATE`. Finance/Projects Accounting must review supporting facts and approve any accounting action under local policy. Keep the as-of date, grace-day parameter, reason, and source evidence visible and auditable.

## Grain and split-line guardrails

- Never flatten the four datasets into one additive fact.
- A split can copy `PROJECT_ASSET_LINE_DETAIL_ID` to multiple asset lines. The bridge therefore pairs stable Oracle detail-row key `PROJ_ASSET_LINE_DTL_UNIQ_ID` with `PROJECT_ASSET_LINE_ID`; joining `F_Project_Cost` through it repeats the source cost for split lines.
- Do not place raw cost, burdened cost, current asset cost, posted amount, or candidate amount on the bridge. Count distinct source and target keys, then aggregate measures from their owning fact.
- Do not sum status snapshots across `AS_OF_DATE`; select one snapshot before aggregation.
- Source cost, assigned asset-line cost, and posted FA amount are lifecycle perspectives, not independently additive balances.

## Governed drill paths

1. `D_Project` / `D_Task` → `F_Project_Cost` for source distribution and COA detail.
2. `F_Project_Cost` (`EXPENDITURE_ITEM_ID`, `LINE_NUM`) → `B_Project_Cost_To_Asset_Line` → `F_Project_Asset_Line` for assignment lineage.
3. `F_Project_Asset_Line` → `F_Project_Capitalization_Status` at a selected `AS_OF_DATE` for workflow state, aging, holds, rejection, and candidate review.
4. Posted status `ASSET_ID` → `D_Asset` → FA transaction and balance facts for source-to-FA traceability.

Use drill-through or explicit bridge filtering; do not create active fact-to-fact relationships.

**Version:** 26B
