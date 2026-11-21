# Oracle Fusion 26D source review

Reviewed November 21, 2026. Oracle lists Financials and Project Management 26D in its October 2026 readiness updates. The repository now uses 26D as its public documentation baseline. The target tenant's release, access, and extract results still need confirmation. [Oracle Cloud Applications Readiness](https://docs.oracle.com/en/cloud/saas/readiness/news.html)

## Source compatibility

| Domain | Public documentation findings | Tenant verification |
|---|---|---|
| Fixed Assets | Oracle still documents the three OTBI subject areas at their existing distribution grains. The ESS reporting extract remains a prerequisite. See [data lineage](data-lineage.md). | Run the ESS extract and the three OTBI exports using the production reporting role. Confirm logical column names, declared CSV keys, and totals for a closed period. |
| Accounts Payable | The 26D documentation still identifies installments with payment schedules and describes invoice and distribution sources. The 26C and 26D feature summaries identify new invoice intake, close, and payment features. The review found no published change to the payment-schedule grain used by the project. [Installments Real Time](https://docs.oracle.com/en/cloud/saas/financials/26d/faofb/Payables-Invoices-Installments-Real-Time-SA-191.html) · [Payables transaction business objects](https://docs.oracle.com/en/cloud/saas/financials/26d/faipp/payables-transaction-business-objects.html) | Run both BI Publisher extracts and reconcile schedule balances and distribution counts under identical date, business unit, currency, and status filters. Check grants, queried columns, and status values. |
| Projects | Oracle documents the cost-distribution join on `EXPENDITURE_ITEM_ID` and `LINE_NUM`, the detail-row key `PROJ_ASSET_LINE_DTL_UNIQ_ID`, and the reuse of the detail-group ID on split asset lines. The 26D Assets guide still describes the mass-addition handoff, and the Financials dictionary links posted asset source lines to `PROJECT_ASSET_LINE_ID`. [Asset line details](https://docs.oracle.com/en/cloud/saas/project-management/26d/oedpp/pjcprjassetlndets-24936.html) · [Project Costing import](https://docs.oracle.com/en/cloud/saas/financials/26d/faalm/how-project-costing-source-lines-are-imported.html) · [FA_ASSET_INVOICES](https://docs.oracle.com/en/cloud/saas/financials/26d/oedmf/faassetinvoices-11792.html) | Run all four BI Publisher extracts and the Projects diagnostics. Check grants, queried columns, status values, and the expected results for split, reversed, held, rejected, transferred, and posted lines. |

The public review found no required changes to the reviewed extract interfaces. Exported columns, declared grains, and Power BI mappings carry forward to the 26D baseline. Tenant verification covers query execution, CSV reconciliation, and Power BI refresh.

## Impact on historical reporting

- **Tax-book depreciation and balances.** In 26D, users can post tax-book depreciation adjustments for closed fiscal years. Oracle applies them from the affected fiscal year through the current fiscal year, and the feature requires no enablement. If the project carries tax-book data and an adjustment is entered, retained depreciation and balance CSVs can become stale. Rerun the ESS extract, reconcile periods in the affected book from the adjusted fiscal year forward, and replace affected CSV partitions before refreshing Power BI. Check depreciation, accumulated reserve, and net book value against Oracle. [Oracle 26D tax-book depreciation adjustment](https://docs.oracle.com/en/cloud/saas/readiness/erp/26d/fins26d/26D-fin-wn-f50297.htm)
- **Existing AP and Projects snapshot behavior.** The extracts read current open amounts, holds, transfer statuses, and posting evidence. A backdated `AS_OF_DATE` changes aging or age calculations while the underlying state still comes from extract time. Use retained snapshots for historical reporting. See the [AP aging contract](../../contracts/ap/ap_aging_schedule.yml) and [Projects capitalization status contract](../../contracts/projects/project_capitalization_status.yml).
- **Planned bulk extracts.** Oracle's 26D Data Extraction Migration Assistant supports migrating BICC jobs to extracts backed by read-only replicated data. This concerns the planned BICC-to-Fabric flow. The current flow uses OTBI and BI Publisher. [Oracle 26D Data Extraction Migration Assistant](https://docs.oracle.com/en/cloud/saas/readiness/erp/26d/fins26d/26D-fin-wn-f51362.htm)

## Release notes reviewed

- [Financials 26C feature summary](https://docs.oracle.com/en/cloud/saas/readiness/erp/26c/fins26c/26C-fin-wn-t78669.htm)
- [Financials 26D feature summary](https://docs.oracle.com/en/cloud/saas/readiness/erp/26d/fins26d/26D-fin-wn-t78734.htm)
- [Project Management 26C What's New](https://docs.oracle.com/en/cloud/saas/readiness/erp/26c/ppm26c/)
- [Project Management 26D feature summary](https://docs.oracle.com/en/cloud/saas/readiness/erp/26d/ppm26d/26D-ppm-wn-t78735.htm)
