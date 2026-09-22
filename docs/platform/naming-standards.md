# Naming Standards

Conventions aligned with Steve Hoberman dimensional modeling practice and this repo's contracts-first workflow.

## Facts

- Pattern: `F_<Domain>_<Process>` (e.g. `F_AP_Aging_Schedule`, `F_Asset_Transaction`)
- One grain per fact; document in contract `grain` and bus matrix row
- Primary key columns listed in contract `primary_key`

## Dimensions

- Pattern: `D_<Concept>` (e.g. `D_Supplier`, `D_COA`, `D_Asset`)
- Conformed across P2C stages; see [`conformed-dimensions.md`](conformed-dimensions.md)

## Bridges

- Pattern: `B_<From>_To_<To>` or invoice-level bridge columns on facts when grain differs
- Bridge columns are **non-additive** with fact measures at the finer grain

## Files and folders

| Artifact | Location |
|----------|----------|
| Contracts | `contracts/<domain>/<name>.yml` |
| BIP extracts | `sql/bip/<domain>/<name>.sql` |
| Layered SQL | `sql/<domain>/staging\|intermediate\|marts\|diagnostics/` |
| Power Query | `powerbi/queries/<domain>/<Fact>.m` |
| Bus matrix | `docs/domains/<domain>/bus-matrix.md` |

## CSV export patterns

Follow contract naming: `{contract_base}_{yyyymm}.csv` or `{contract_base}_{yyyymmdd}.csv` as documented per domain.

**Version:** 26B
