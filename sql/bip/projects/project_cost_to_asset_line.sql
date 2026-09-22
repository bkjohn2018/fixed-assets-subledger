-- BIP extract: non-additive cost-to-asset-line lineage bridge
-- Grain: PROJ_ASSET_LINE_DTL_UNIQ_ID
-- Split asset lines legitimately repeat a cost distribution across asset lines.

WITH bridge_rows AS (
    SELECT
        d.proj_asset_line_dtl_uniq_id,
        d.project_asset_line_detail_id,
        pal.project_asset_line_id,
        d.expenditure_item_id,
        d.line_num,
        cdl.project_id,
        cdl.task_id,
        d.reversed_flag AS detail_reversal_flag
    FROM pjc_prj_asset_ln_dets d
    INNER JOIN pjc_prj_asset_lns_all pal
        ON d.project_asset_line_detail_id = pal.project_asset_line_detail_id
    INNER JOIN pjc_cost_dist_lines_all cdl
        ON d.expenditure_item_id = cdl.expenditure_item_id
        AND d.line_num = cdl.line_num
),

profiled AS (
    SELECT
        br.*,
        COUNT(DISTINCT br.project_asset_line_id) OVER (
            PARTITION BY br.expenditure_item_id, br.line_num
        ) AS cost_to_asset_line_fanout,
        COUNT(*) OVER (
            PARTITION BY br.project_asset_line_id
        ) AS asset_line_to_cost_fanin
    FROM bridge_rows br
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
