-- BIP extract: Projects capitalization lifecycle snapshot
-- Grain: PROJECT_ASSET_LINE_ID + AS_OF_DATE
-- Parameters: @AS_OF_DATE, @GRACE_DAYS

WITH params AS (
    SELECT
        TRUNC(CAST(@AS_OF_DATE AS DATE)) AS as_of_date,
        CAST(@GRACE_DAYS AS NUMBER) AS grace_days
    FROM dual
),

cost_flags AS (
    SELECT
        pal.project_asset_line_id,
        CASE
            WHEN MIN(CASE WHEN cdl.capitalizable_flag = 'Y' THEN 1 ELSE 0 END) = 1 THEN 'Y'
            ELSE 'N'
        END AS capitalizable_flag
    FROM pjc_prj_asset_lns_all pal
    INNER JOIN pjc_prj_asset_ln_dets d
        ON pal.project_asset_line_detail_id = d.project_asset_line_detail_id
    INNER JOIN pjc_cost_dist_lines_all cdl
        ON d.expenditure_item_id = cdl.expenditure_item_id
        AND d.line_num = cdl.line_num
    WHERE COALESCE(d.reversed_flag, 'N') <> 'Y'
    GROUP BY pal.project_asset_line_id
),

mass_additions AS (
    SELECT
        fma.project_asset_line_id,
        COUNT(*) AS mass_addition_count,
        MAX(CASE WHEN UPPER(TRIM(fma.posting_status)) = 'ON HOLD' THEN 1 ELSE 0 END) AS has_fa_hold,
        LISTAGG(DISTINCT fma.posting_status, ',') WITHIN GROUP (
            ORDER BY fma.posting_status
        ) AS mass_addition_status_profile
    FROM fa_mass_additions fma
    WHERE fma.project_asset_line_id IS NOT NULL
    GROUP BY fma.project_asset_line_id
),

posted_evidence AS (
    SELECT
        fai.project_asset_line_id,
        COUNT(DISTINCT fai.source_line_id) AS posted_source_line_count,
        SUM(COALESCE(fai.fixed_assets_cost, 0)) AS posted_fixed_assets_cost,
        CASE
            WHEN COUNT(DISTINCT fai.asset_id) = 1 THEN MIN(fai.asset_id)
        END AS fa_asset_id
    FROM fa_asset_invoices fai
    WHERE fai.project_asset_line_id IS NOT NULL
    GROUP BY fai.project_asset_line_id
),

classified AS (
    SELECT
        pal.project_asset_line_id,
        p.as_of_date,
        pal.project_asset_id,
        pal.project_id,
        pal.task_id,
        pal.current_asset_cost,
        pal.transfer_status_code,
        pal.transfer_rejection_reason,
        COALESCE(cf.capitalizable_flag, 'N') AS capitalizable_flag,
        COALESCE(pa.capital_hold_flag, 'N') AS capital_hold_flag,
        TRUNC(p.as_of_date) - TRUNC(CAST(pal.creation_date AS DATE)) AS age_days,
        COALESCE(ma.mass_addition_count, 0) AS mass_addition_count,
        ma.mass_addition_status_profile,
        COALESCE(pe.posted_source_line_count, 0) AS posted_source_line_count,
        COALESCE(pe.posted_fixed_assets_cost, 0) AS posted_fixed_assets_cost,
        pe.fa_asset_id,
        CASE
            WHEN COALESCE(pe.posted_source_line_count, 0) > 0 THEN 'POSTED_CAPITALIZED'
            WHEN COALESCE(pa.capital_hold_flag, 'N') = 'Y'
                OR COALESCE(ma.has_fa_hold, 0) = 1 THEN 'HELD'
            WHEN pal.transfer_rejection_reason IS NOT NULL THEN 'TRANSFER_REJECTED'
            WHEN COALESCE(ma.mass_addition_count, 0) > 0 THEN 'TRANSFERRED_NOT_POSTED'
            WHEN pal.project_asset_id = 0 OR pal.unassigned_line_flag = 'Y' THEN 'GENERATED_UNASSIGNED'
            ELSE 'POLICY_REVIEW_REQUIRED'
        END AS lifecycle_status,
        CASE
            WHEN COALESCE(cf.capitalizable_flag, 'N') = 'Y'
                AND TRUNC(p.as_of_date) - TRUNC(CAST(pal.creation_date AS DATE)) >= p.grace_days
                AND COALESCE(pe.posted_source_line_count, 0) = 0
                AND COALESCE(pa.capital_hold_flag, 'N') <> 'Y'
                AND COALESCE(ma.has_fa_hold, 0) = 0
                THEN 1
            ELSE 0
        END AS is_capitalization_candidate
    FROM pjc_prj_asset_lns_all pal
    CROSS JOIN params p
    LEFT JOIN pjc_prj_assets_all pa
        ON pal.project_asset_id = pa.project_asset_id
        AND pal.project_asset_id <> 0
    LEFT JOIN cost_flags cf
        ON pal.project_asset_line_id = cf.project_asset_line_id
    LEFT JOIN mass_additions ma
        ON pal.project_asset_line_id = ma.project_asset_line_id
    LEFT JOIN posted_evidence pe
        ON pal.project_asset_line_id = pe.project_asset_line_id
)

SELECT
    project_asset_line_id,
    as_of_date,
    project_asset_id,
    project_id,
    task_id,
    current_asset_cost,
    transfer_status_code,
    transfer_rejection_reason,
    capitalizable_flag,
    capital_hold_flag,
    age_days,
    mass_addition_count,
    mass_addition_status_profile,
    posted_source_line_count,
    posted_fixed_assets_cost,
    fa_asset_id,
    lifecycle_status,
    is_capitalization_candidate
FROM classified
