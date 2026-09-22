-- BIP extract: summarized Projects asset lines
-- Grain: PROJECT_ASSET_LINE_ID

SELECT
    pal.project_asset_line_id,
    pal.project_asset_line_detail_id,
    pal.project_asset_id,
    pal.project_id,
    pal.task_id,
    pal.org_id,
    pal.line_type,
    pal.description,
    pal.original_asset_cost,
    pal.current_asset_cost,
    pal.cip_ccid,
    pal.transfer_status_code,
    pal.transfer_rejection_reason,
    pal.unassigned_line_flag,
    pal.rev_proj_asset_line_id,
    pal.creation_date,
    pa.asset_name AS project_asset_name,
    pa.book_type_code,
    pa.date_placed_in_service,
    pa.capitalized_flag,
    pa.capitalized_date,
    pa.capital_hold_flag,
    pa.fa_asset_id
FROM pjc_prj_asset_lns_all pal
LEFT JOIN pjc_prj_assets_all pa
    ON pal.project_asset_id = pa.project_asset_id
    AND pal.project_asset_id <> 0
