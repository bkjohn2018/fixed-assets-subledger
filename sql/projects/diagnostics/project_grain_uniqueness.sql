-- Diagnostic: contract-grain duplicate counts; each result should be zero rows.

SELECT
    'F_PROJECT_COST' AS diagnostic_entity,
    expenditure_item_id,
    line_num,
    COUNT(*) AS occurrence_count
FROM fact_project_cost
GROUP BY expenditure_item_id, line_num
HAVING COUNT(*) > 1;

SELECT
    'F_PROJECT_ASSET_LINE' AS diagnostic_entity,
    project_asset_line_id,
    COUNT(*) AS occurrence_count
FROM fact_project_asset_line
GROUP BY project_asset_line_id
HAVING COUNT(*) > 1;

SELECT
    'B_PROJECT_COST_TO_ASSET_LINE' AS diagnostic_entity,
    proj_asset_line_dtl_uniq_id,
    project_asset_line_id,
    COUNT(*) AS occurrence_count
FROM bridge_project_cost_to_asset_line
GROUP BY proj_asset_line_dtl_uniq_id, project_asset_line_id
HAVING COUNT(*) > 1;

SELECT
    'F_PROJECT_CAPITALIZATION_STATUS' AS diagnostic_entity,
    project_asset_line_id,
    as_of_date,
    COUNT(*) AS occurrence_count
FROM fact_project_capitalization_status
GROUP BY project_asset_line_id, as_of_date
HAVING COUNT(*) > 1;
