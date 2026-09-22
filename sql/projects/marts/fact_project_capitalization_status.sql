-- Mart: F_Project_Capitalization_Status
-- Grain and output columns match contracts/projects/project_capitalization_status.yml.

SELECT
    l.project_asset_line_id,
    x.as_of_date,
    l.project_asset_id,
    l.project_id,
    l.task_id,
    l.current_asset_cost,
    l.transfer_status_code,
    l.transfer_rejection_reason,
    x.capitalizable_flag,
    l.capital_hold_flag,
    x.age_days,
    COALESCE(e.mass_addition_count, 0) AS mass_addition_count,
    e.mass_addition_status_profile,
    COALESCE(e.posted_source_line_count, 0) AS posted_source_line_count,
    COALESCE(e.posted_fixed_assets_cost, 0) AS posted_fixed_assets_cost,
    e.fa_asset_id,
    x.lifecycle_status,
    x.is_capitalization_candidate
FROM stg_project_asset_line l
INNER JOIN int_project_capitalization_classification x
    ON l.project_asset_line_id = x.project_asset_line_id
    AND x.record_grain = 'ASSET_LINE'
LEFT JOIN stg_project_capitalization_evidence e
    ON l.project_asset_line_id = e.project_asset_line_id
