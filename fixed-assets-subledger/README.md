# Fixed Assets Subledger

Oracle Fusion Fixed Assets (25C) subledger-only data model driven by BI Publisher flat-file extracts.

## Purpose

This repository provides a standardized data model for Fixed Assets reporting and analytics, focusing on subledger-only operations without SLA (Subledger Accounting) dependencies. The model uses `CODE_COMBINATION_ID` for Chart of Accounts integration.

## Data Flow

```
BI Publisher → CSV Files → Power BI
     ↓
Oracle/ADW External Tables (future: BICC → Fabric)
```

## Star Schema Overview

```
                    D_Time
                       |
                       |
              F_Depreciation_Period
                       |
                       |
              F_Asset_Balance_Period ←→ D_Asset ←→ F_Asset_Transaction
                       |                      |
                       |                      |
                   D_Book ←→ D_COA (via CODE_COMBINATION_ID)
```

## Repository Structure

- `contracts/` - Data contract definitions (YAML)
- `sql/bip/` - BI Publisher Logical SQL queries
- `sql/ddl/` - External table definitions for CSV staging
- `sql/views/` - Helper views for unified reporting
- `powerbi/queries/` - Power Query M code
- `powerbi/` - DAX measures and model definitions
- `scripts/` - Validation and utility scripts
- `.github/workflows/` - CI/CD pipeline

## Fact Tables

### F_Asset_Transaction
- **Grain**: Transaction header level
- **Key**: `TRANSACTION_HEADER_ID`
- **Includes**: `CODE_COMBINATION_ID` for COA integration
- **Measures**: Cost deltas, depreciation reserves, proceeds, gain/loss

### F_Depreciation_Period
- **Grain**: Asset book period level
- **Key**: `[ASSET_ID, BOOK_TYPE_CODE, PERIOD_COUNTER]`
- **Measures**: Depreciation amounts (period, YTD, ITD)

### F_Asset_Balance_Period
- **Grain**: Asset book period level
- **Key**: `[ASSET_ID, BOOK_TYPE_CODE, PERIOD_COUNTER]`
- **Measures**: Cost balances, movements, net book value

## Key Design Decisions

1. **Subledger-Only**: No SLA table dependencies
2. **CCID Integration**: Uses `CODE_COMBINATION_ID` for COA joins
3. **Header Grain**: Transaction facts at header level (not distribution)
4. **No Segment Columns**: Facts use CCID only, not individual segment values
5. **Contract-First**: All changes require contract updates before SQL/PBI changes

## Usage

### BI Publisher Setup

1. Create reports using the Logical SQL in `sql/bip/`
2. Set parameters: `@BOOK_TYPE_CODE`, `@START_DATE`, `@END_DATE`, `@PERIOD_NAME`
3. Export as CSV with naming convention: `{table_name}_{period}.csv`
4. Place CSV files in `data/` directory

### Power BI Integration

1. Use Power Query files in `powerbi/queries/` to load CSV data
2. Apply DAX measures from `powerbi/measures.dax`
3. Set up relationships using `CODE_COMBINATION_ID` to your existing COA dimension

### Validation

Run the contract validator:
```bash
python scripts/validate_contracts.py
```

Expected output: `[OK] contracts validated`

## Rollforward Validation

Verify data integrity using this calculation:
```
Cost_Beg + Additions + Adjustments + Transfers_Net - Retirements_Cost = Cost_End (derived)
```

## Integration with Existing COA

Join to your existing Chart of Accounts via `CODE_COMBINATION_ID`:
```sql
SELECT fa.*, coa.SEGMENT1, coa.SEGMENT2, coa.SEGMENT3
FROM F_Asset_Transaction fa
JOIN D_COA coa ON fa.CODE_COMBINATION_ID = coa.CODE_COMBINATION_ID
```

## Contribution Guidelines

1. **Contract-First**: Always update data contracts before SQL or Power BI changes
2. **Column Naming**: Keep exact column names to avoid Power BI rewiring
3. **Pull Requests**: Required for all contract changes
4. **Testing**: Ensure CI passes (SQLFluff + contract validation)

## Future Enhancements

- **Task A**: Distribution-level transaction variant
- **Task B**: Complete Power BI model.json with relationships
- **Task C**: Enhanced README with BI Publisher runbook
- **Task D**: Pre-commit hooks for local validation

## Oracle Fusion 25C Compatibility

All data contracts and SQL queries are designed for Oracle Fusion 25C. Version compatibility is enforced through the `version: 25C` field in contract definitions.

## Troubleshooting

### Common Issues

1. **Power BI Refresh Failures**: Check CSV file paths and encoding (UTF-8)
2. **Missing Data**: Verify BI Publisher parameter values and date ranges
3. **Relationship Errors**: Ensure `CODE_COMBINATION_ID` matches between FA and COA dimensions

### Support

For issues or questions, please create a GitHub issue with:
- Oracle Fusion version
- Error messages
- Sample data (if applicable)
- Steps to reproduce
