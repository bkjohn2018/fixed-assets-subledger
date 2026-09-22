-- Staging normalization: detail-row lineage expanded to each matching asset line
-- Grain: PROJ_ASSET_LINE_DTL_UNIQ_ID + PROJECT_ASSET_LINE_ID

SELECT
    d.proj_asset_line_dtl_uniq_id,
    d.project_asset_line_detail_id,
    pal.project_asset_line_id,
    d.expenditure_item_id,
    d.line_num,
    cdl.project_id,
    cdl.task_id,
    UPPER(TRIM(COALESCE(d.reversed_flag, 'N'))) AS detail_reversal_flag
FROM pjc_prj_asset_ln_dets d
INNER JOIN pjc_prj_asset_lns_all pal
    ON d.project_asset_line_detail_id = pal.project_asset_line_detail_id
INNER JOIN pjc_cost_dist_lines_all cdl
    ON d.expenditure_item_id = cdl.expenditure_item_id
    AND d.line_num = cdl.line_num
