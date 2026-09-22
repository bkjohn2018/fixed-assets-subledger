-- Intermediate lifecycle classification for cost and asset-line grains
-- Bind parameters: :as_of_date, :grace_days
-- Inputs are the logical staging queries in sql/projects/staging.

WITH params AS (
    SELECT
        TRUNC(CAST(:as_of_date AS DATE)) AS as_of_date,
        CAST(:grace_days AS NUMBER) AS grace_days
    FROM dual
),

asset_cost_flags AS (
    SELECT
        b.project_asset_line_id,
        CASE
            WHEN MIN(CASE WHEN c.capitalizable_flag = 'Y' THEN 1 ELSE 0 END) = 1 THEN 'Y'
            ELSE 'N'
        END AS capitalizable_flag
    FROM stg_project_cost_to_asset_line b
    INNER JOIN stg_project_cost c
        ON
            b.expenditure_item_id = c.expenditure_item_id
            AND b.line_num = c.line_num
    WHERE b.detail_reversal_flag <> 'Y'
    GROUP BY b.project_asset_line_id
),

active_cost_asset_lines AS (
    SELECT DISTINCT
        expenditure_item_id,
        line_num,
        project_asset_line_id
    FROM stg_project_cost_to_asset_line
    WHERE detail_reversal_flag <> 'Y'
),

cost_evidence AS (
    SELECT
        b.expenditure_item_id,
        b.line_num,
        COUNT(DISTINCT b.project_asset_line_id) AS asset_line_count,
        MAX(
            CASE
                WHEN l.capital_hold_flag = 'Y' OR COALESCE(e.has_fa_hold, 0) = 1 THEN 1
                ELSE 0
            END
        ) AS has_capital_hold,
        MAX(CASE WHEN l.transfer_rejection_reason IS NOT NULL THEN 1 ELSE 0 END) AS has_rejection,
        SUM(COALESCE(e.posted_asset_count, 0)) AS posted_asset_count,
        SUM(COALESCE(e.mass_addition_count, 0)) AS mass_addition_count,
        COUNT(DISTINCT CASE
            WHEN l.project_asset_id = 0 OR l.unassigned_line_flag = 'Y' THEN l.project_asset_line_id
        END) AS unassigned_count
    FROM active_cost_asset_lines b
    INNER JOIN stg_project_asset_line l
        ON b.project_asset_line_id = l.project_asset_line_id
    LEFT JOIN stg_project_capitalization_evidence e
        ON b.project_asset_line_id = e.project_asset_line_id
    GROUP BY b.expenditure_item_id, b.line_num
),

cost_rows AS (
    SELECT
        'COST' AS record_grain,
        c.expenditure_item_id,
        c.line_num,
        CAST(NULL AS NUMBER) AS project_asset_line_id,
        p.as_of_date,
        TRUNC(p.as_of_date) - TRUNC(c.prvdr_gl_date) AS age_days,
        c.capitalizable_flag,
        COALESCE(ce.has_capital_hold, 0) AS has_capital_hold,
        COALESCE(ce.asset_line_count, 0) AS asset_line_count,
        COALESCE(ce.mass_addition_count, 0) AS mass_addition_count,
        COALESCE(ce.posted_asset_count, 0) AS posted_asset_count,
        CASE
            WHEN COALESCE(ce.posted_asset_count, 0) > 0 THEN 'POSTED_CAPITALIZED'
            WHEN COALESCE(ce.has_capital_hold, 0) = 1 THEN 'HELD'
            WHEN COALESCE(ce.has_rejection, 0) = 1 THEN 'TRANSFER_REJECTED'
            WHEN COALESCE(ce.mass_addition_count, 0) > 0 THEN 'TRANSFERRED_NOT_POSTED'
            WHEN
                COALESCE(ce.asset_line_count, 0) > 0
                AND ce.unassigned_count = ce.asset_line_count THEN 'GENERATED_UNASSIGNED'
            WHEN
                COALESCE(ce.asset_line_count, 0) = 0
                AND c.capitalizable_flag = 'Y'
                AND TRUNC(p.as_of_date) - TRUNC(c.prvdr_gl_date) < p.grace_days
                THEN 'CAPITALIZABLE_NOT_GENERATED'
            ELSE 'POLICY_REVIEW_REQUIRED'
        END AS lifecycle_status,
        CASE
            WHEN
                c.capitalizable_flag = 'Y'
                AND TRUNC(p.as_of_date) - TRUNC(c.prvdr_gl_date) >= p.grace_days
                AND COALESCE(ce.posted_asset_count, 0) = 0
                AND COALESCE(ce.has_capital_hold, 0) = 0 THEN 1
            ELSE 0
        END AS is_capitalization_candidate
    FROM stg_project_cost c
    CROSS JOIN params p
    LEFT JOIN cost_evidence ce
        ON
            c.expenditure_item_id = ce.expenditure_item_id
            AND c.line_num = ce.line_num
),

asset_line_rows AS (
    SELECT
        'ASSET_LINE' AS record_grain,
        CAST(NULL AS NUMBER) AS expenditure_item_id,
        CAST(NULL AS NUMBER) AS line_num,
        l.project_asset_line_id,
        p.as_of_date,
        TRUNC(p.as_of_date) - TRUNC(CAST(l.creation_date AS DATE)) AS age_days,
        COALESCE(cf.capitalizable_flag, 'N') AS capitalizable_flag,
        CASE
            WHEN l.capital_hold_flag = 'Y' OR COALESCE(e.has_fa_hold, 0) = 1 THEN 1
            ELSE 0
        END AS has_capital_hold,
        1 AS asset_line_count,
        COALESCE(e.mass_addition_count, 0) AS mass_addition_count,
        COALESCE(e.posted_asset_count, 0) AS posted_asset_count,
        CASE
            WHEN COALESCE(e.posted_asset_count, 0) > 0 THEN 'POSTED_CAPITALIZED'
            WHEN l.capital_hold_flag = 'Y' OR COALESCE(e.has_fa_hold, 0) = 1 THEN 'HELD'
            WHEN l.transfer_rejection_reason IS NOT NULL THEN 'TRANSFER_REJECTED'
            WHEN COALESCE(e.mass_addition_count, 0) > 0 THEN 'TRANSFERRED_NOT_POSTED'
            WHEN l.project_asset_id = 0 OR l.unassigned_line_flag = 'Y' THEN 'GENERATED_UNASSIGNED'
            ELSE 'POLICY_REVIEW_REQUIRED'
        END AS lifecycle_status,
        CASE
            WHEN
                COALESCE(cf.capitalizable_flag, 'N') = 'Y'
                AND TRUNC(p.as_of_date) - TRUNC(CAST(l.creation_date AS DATE)) >= p.grace_days
                AND COALESCE(e.posted_asset_count, 0) = 0
                AND l.capital_hold_flag <> 'Y'
                AND COALESCE(e.has_fa_hold, 0) = 0 THEN 1
            ELSE 0
        END AS is_capitalization_candidate
    FROM stg_project_asset_line l
    CROSS JOIN params p
    LEFT JOIN asset_cost_flags cf
        ON l.project_asset_line_id = cf.project_asset_line_id
    LEFT JOIN stg_project_capitalization_evidence e
        ON l.project_asset_line_id = e.project_asset_line_id
)

SELECT * FROM cost_rows
UNION ALL
SELECT * FROM asset_line_rows
