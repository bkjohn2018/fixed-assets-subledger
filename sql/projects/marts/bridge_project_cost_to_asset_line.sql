-- Mart: B_Project_Cost_To_Asset_Line
-- Grain and output columns match contracts/projects/project_cost_to_asset_line.yml.

WITH profiled AS (
    SELECT
        b.*,
        COUNT(DISTINCT b.project_asset_line_id) OVER (
            PARTITION BY b.expenditure_item_id, b.line_num
        ) AS cost_to_asset_line_fanout,
        COUNT(*) OVER (
            PARTITION BY b.project_asset_line_id
        ) AS asset_line_to_cost_fanin
    FROM stg_project_cost_to_asset_line b
)

SELECT
    proj_asset_line_dtl_uniq_id,
    project_asset_line_detail_id,
    project_asset_line_id,
    expenditure_item_id,
    line_num,
    project_id,
    task_id,
    detail_reversal_flag,
    cost_to_asset_line_fanout,
    asset_line_to_cost_fanin,
    CASE WHEN cost_to_asset_line_fanout > 1 THEN 1 ELSE 0 END AS is_split_fanout
FROM profiled
