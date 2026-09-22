-- Diagnostic: profile source codes and flag non-governed lifecycle outputs.

SELECT
    'PJC_PRJ_ASSET_LNS_ALL.TRANSFER_STATUS_CODE' AS source_field,
    COALESCE(transfer_status_code, '<NULL>') AS source_value,
    COUNT(*) AS row_count
FROM stg_project_asset_line
GROUP BY COALESCE(transfer_status_code, '<NULL>')
ORDER BY row_count DESC;

SELECT
    'FA_MASS_ADDITIONS.POSTING_STATUS' AS source_field,
    COALESCE(UPPER(TRIM(posting_status)), '<NULL>') AS source_value,
    COUNT(*) AS row_count
FROM fa_mass_additions
GROUP BY COALESCE(UPPER(TRIM(posting_status)), '<NULL>')
ORDER BY row_count DESC;

SELECT lifecycle_status, COUNT(*) AS row_count
FROM fact_project_capitalization_status
GROUP BY lifecycle_status
HAVING lifecycle_status NOT IN (
    'POSTED_CAPITALIZED',
    'TRANSFERRED_NOT_POSTED',
    'TRANSFER_REJECTED',
    'GENERATED_UNASSIGNED',
    'CAPITALIZABLE_NOT_GENERATED',
    'HELD',
    'POLICY_REVIEW_REQUIRED'
);
