-- Staging normalization: FA workflow and posted evidence preaggregated by project asset line
-- Grain: PROJECT_ASSET_LINE_ID

WITH mass_additions AS (
    SELECT
        fma.project_asset_line_id,
        COUNT(*) AS mass_addition_count,
        MAX(CASE WHEN UPPER(TRIM(fma.posting_status)) = 'ON HOLD' THEN 1 ELSE 0 END) AS has_fa_hold,
        LISTAGG(DISTINCT UPPER(TRIM(fma.posting_status)), ',') WITHIN GROUP (
            ORDER BY UPPER(TRIM(fma.posting_status))
        ) AS mass_addition_status_profile
    FROM fa_mass_additions fma
    WHERE fma.project_asset_line_id IS NOT NULL
    GROUP BY fma.project_asset_line_id
),

posted AS (
    SELECT
        fai.project_asset_line_id,
        COUNT(DISTINCT fai.source_line_id) AS posted_source_line_count,
        SUM(COALESCE(fai.fixed_assets_cost, 0)) AS posted_fixed_assets_cost,
        COUNT(DISTINCT fai.asset_id) AS posted_asset_count,
        CASE
            WHEN COUNT(DISTINCT fai.asset_id) = 1 THEN MIN(fai.asset_id)
        END AS fa_asset_id
    FROM fa_asset_invoices fai
    WHERE fai.project_asset_line_id IS NOT NULL
    GROUP BY fai.project_asset_line_id
),

keys AS (
    SELECT project_asset_line_id FROM mass_additions
    UNION
    SELECT project_asset_line_id FROM posted
)

SELECT
    k.project_asset_line_id,
    COALESCE(ma.mass_addition_count, 0) AS mass_addition_count,
    COALESCE(ma.has_fa_hold, 0) AS has_fa_hold,
    ma.mass_addition_status_profile,
    COALESCE(p.posted_source_line_count, 0) AS posted_source_line_count,
    COALESCE(p.posted_fixed_assets_cost, 0) AS posted_fixed_assets_cost,
    COALESCE(p.posted_asset_count, 0) AS posted_asset_count,
    p.fa_asset_id
FROM keys k
LEFT JOIN mass_additions ma
    ON k.project_asset_line_id = ma.project_asset_line_id
LEFT JOIN posted p
    ON k.project_asset_line_id = p.project_asset_line_id
