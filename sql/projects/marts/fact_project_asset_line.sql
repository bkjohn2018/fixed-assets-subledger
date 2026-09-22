-- Mart: F_Project_Asset_Line
-- Grain and output columns match contracts/projects/project_asset_line.yml.

SELECT
    project_asset_line_id,
    project_asset_line_detail_id,
    project_asset_id,
    project_id,
    task_id,
    org_id,
    line_type,
    description,
    original_asset_cost,
    current_asset_cost,
    cip_ccid,
    transfer_status_code,
    transfer_rejection_reason,
    unassigned_line_flag,
    rev_proj_asset_line_id,
    creation_date,
    project_asset_name,
    book_type_code,
    date_placed_in_service,
    capitalized_flag,
    capitalized_date,
    capital_hold_flag,
    fa_asset_id
FROM stg_project_asset_line
