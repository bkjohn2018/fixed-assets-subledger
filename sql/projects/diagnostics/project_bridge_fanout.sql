-- Diagnostic: expected split fanout and non-additive bridge shape.

SELECT
    expenditure_item_id,
    line_num,
    COUNT(*) AS bridge_row_count,
    COUNT(DISTINCT project_asset_line_id) AS asset_line_count,
    MIN(cost_to_asset_line_fanout) AS recorded_fanout_min,
    MAX(cost_to_asset_line_fanout) AS recorded_fanout_max,
    SUM(CASE WHEN detail_reversal_flag = 'Y' THEN 1 ELSE 0 END) AS reversed_link_count
FROM bridge_project_cost_to_asset_line
GROUP BY expenditure_item_id, line_num
HAVING COUNT(DISTINCT project_asset_line_id) > 1
    OR MIN(cost_to_asset_line_fanout) <> MAX(cost_to_asset_line_fanout)
ORDER BY asset_line_count DESC, expenditure_item_id, line_num
