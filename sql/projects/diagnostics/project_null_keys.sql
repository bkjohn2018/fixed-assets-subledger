-- Diagnostic: required and conformed-key null rates.

SELECT
    'F_PROJECT_COST' AS diagnostic_entity,
    COUNT(*) AS occurrence_count,
    SUM(CASE WHEN expenditure_item_id IS NULL OR line_num IS NULL THEN 1 ELSE 0 END) AS null_primary_keys,
    SUM(CASE WHEN project_id IS NULL THEN 1 ELSE 0 END) AS null_project_ids,
    SUM(CASE WHEN task_id IS NULL THEN 1 ELSE 0 END) AS null_task_ids,
    SUM(CASE WHEN code_combination_id IS NULL THEN 1 ELSE 0 END) AS null_code_combination_ids
FROM fact_project_cost;

SELECT
    'F_PROJECT_ASSET_LINE' AS diagnostic_entity,
    COUNT(*) AS occurrence_count,
    SUM(CASE WHEN project_asset_line_id IS NULL THEN 1 ELSE 0 END) AS null_primary_keys,
    SUM(CASE WHEN project_id IS NULL THEN 1 ELSE 0 END) AS null_project_ids,
    SUM(CASE WHEN task_id IS NULL THEN 1 ELSE 0 END) AS null_task_ids
FROM fact_project_asset_line;

SELECT
    'B_PROJECT_COST_TO_ASSET_LINE' AS diagnostic_entity,
    COUNT(*) AS occurrence_count,
    SUM(
        CASE
            WHEN proj_asset_line_dtl_uniq_id IS NULL OR project_asset_line_id IS NULL THEN 1
            ELSE 0
        END
    ) AS null_primary_keys,
    SUM(CASE WHEN expenditure_item_id IS NULL OR line_num IS NULL THEN 1 ELSE 0 END) AS null_cost_keys,
    SUM(CASE WHEN project_id IS NULL THEN 1 ELSE 0 END) AS null_project_ids
FROM bridge_project_cost_to_asset_line;

SELECT
    'F_PROJECT_CAPITALIZATION_STATUS' AS diagnostic_entity,
    COUNT(*) AS occurrence_count,
    SUM(CASE WHEN project_asset_line_id IS NULL OR as_of_date IS NULL THEN 1 ELSE 0 END) AS null_primary_keys,
    SUM(CASE WHEN project_id IS NULL THEN 1 ELSE 0 END) AS null_project_ids,
    SUM(CASE WHEN task_id IS NULL THEN 1 ELSE 0 END) AS null_task_ids
FROM fact_project_capitalization_status;
