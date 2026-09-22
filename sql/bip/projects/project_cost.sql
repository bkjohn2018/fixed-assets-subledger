-- BIP extract: project cost distribution lines with preaggregated lifecycle evidence
-- Grain: EXPENDITURE_ITEM_ID + LINE_NUM
-- Parameters: @AS_OF_DATE, @GRACE_DAYS

WITH params AS (
    SELECT
        TRUNC(CAST(@AS_OF_DATE AS DATE)) AS as_of_date,
        CAST(@GRACE_DAYS AS NUMBER) AS grace_days
    FROM dual
),

mass_additions AS (
    SELECT
        fma.project_asset_line_id,
        COUNT(*) AS mass_addition_count,
        MAX(CASE WHEN UPPER(TRIM(fma.posting_status)) = 'ON HOLD' THEN 1 ELSE 0 END) AS has_fa_hold
    FROM fa_mass_additions fma
    WHERE fma.project_asset_line_id IS NOT NULL
    GROUP BY fma.project_asset_line_id
),

asset_line_posting AS (
    SELECT
        pal.project_asset_line_id,
        pal.project_asset_line_detail_id,
        pal.project_asset_id,
        pal.transfer_rejection_reason,
        CASE
            WHEN COALESCE(pa.capital_hold_flag, 'N') = 'Y' OR COALESCE(ma.has_fa_hold, 0) = 1 THEN 'Y'
            ELSE 'N'
        END AS capital_hold_flag,
        COALESCE(ma.mass_addition_count, 0) AS mass_addition_count,
        COUNT(DISTINCT fai.source_line_id) AS posted_asset_count
    FROM pjc_prj_asset_lns_all pal
    LEFT JOIN pjc_prj_assets_all pa
        ON pal.project_asset_id = pa.project_asset_id
        AND pal.project_asset_id <> 0
    LEFT JOIN mass_additions ma
        ON pal.project_asset_line_id = ma.project_asset_line_id
    LEFT JOIN fa_asset_invoices fai
        ON pal.project_asset_line_id = fai.project_asset_line_id
    GROUP BY
        pal.project_asset_line_id,
        pal.project_asset_line_detail_id,
        pal.project_asset_id,
        pal.transfer_rejection_reason,
        CASE
            WHEN COALESCE(pa.capital_hold_flag, 'N') = 'Y' OR COALESCE(ma.has_fa_hold, 0) = 1 THEN 'Y'
            ELSE 'N'
        END,
        COALESCE(ma.mass_addition_count, 0)
),

active_cost_asset_lines AS (
    SELECT DISTINCT
        d.expenditure_item_id,
        d.line_num,
        alp.project_asset_line_id
    FROM pjc_prj_asset_ln_dets d
    INNER JOIN asset_line_posting alp
        ON d.project_asset_line_detail_id = alp.project_asset_line_detail_id
    WHERE COALESCE(d.reversed_flag, 'N') <> 'Y'
),

cost_evidence AS (
    SELECT
        m.expenditure_item_id,
        m.line_num,
        COUNT(DISTINCT alp.project_asset_line_id) AS asset_line_count,
        COUNT(DISTINCT CASE WHEN alp.project_asset_id = 0 THEN alp.project_asset_line_id END) AS unassigned_count,
        SUM(COALESCE(alp.posted_asset_count, 0)) AS posted_asset_count,
        SUM(COALESCE(alp.mass_addition_count, 0)) AS mass_addition_count,
        MAX(CASE WHEN alp.capital_hold_flag = 'Y' THEN 1 ELSE 0 END) AS has_capital_hold,
        MAX(CASE WHEN alp.transfer_rejection_reason IS NOT NULL THEN 1 ELSE 0 END) AS has_transfer_rejection
    FROM active_cost_asset_lines m
    INNER JOIN asset_line_posting alp
        ON m.project_asset_line_id = alp.project_asset_line_id
    GROUP BY m.expenditure_item_id, m.line_num
),

classified AS (
    SELECT
        cdl.expenditure_item_id,
        cdl.line_num,
        cdl.project_id,
        cdl.task_id,
        cdl.org_id,
        cdl.raw_cost_dr_ccid AS code_combination_id,
        cdl.prvdr_gl_date,
        cdl.capitalizable_flag,
        cdl.reversed_flag,
        cdl.denom_currency_code,
        cdl.denom_raw_cost,
        cdl.denom_burdened_cost,
        cdl.acct_currency_code,
        cdl.acct_raw_cost,
        cdl.acct_burdened_cost,
        p.as_of_date,
        TRUNC(p.as_of_date) - TRUNC(cdl.prvdr_gl_date) AS age_days,
        COALESCE(e.asset_line_count, 0) AS asset_line_count,
        COALESCE(e.posted_asset_count, 0) AS posted_asset_count,
        COALESCE(e.has_capital_hold, 0) AS has_capital_hold,
        CASE
            WHEN COALESCE(e.posted_asset_count, 0) > 0 THEN 'POSTED_CAPITALIZED'
            WHEN COALESCE(e.has_capital_hold, 0) = 1 THEN 'HELD'
            WHEN COALESCE(e.has_transfer_rejection, 0) = 1 THEN 'TRANSFER_REJECTED'
            WHEN COALESCE(e.mass_addition_count, 0) > 0 THEN 'TRANSFERRED_NOT_POSTED'
            WHEN COALESCE(e.asset_line_count, 0) > 0
                AND e.unassigned_count = e.asset_line_count THEN 'GENERATED_UNASSIGNED'
            WHEN COALESCE(e.asset_line_count, 0) = 0
                AND cdl.capitalizable_flag = 'Y'
                AND TRUNC(p.as_of_date) - TRUNC(cdl.prvdr_gl_date) >= p.grace_days
                THEN 'POLICY_REVIEW_REQUIRED'
            WHEN COALESCE(e.asset_line_count, 0) = 0
                AND cdl.capitalizable_flag = 'Y' THEN 'CAPITALIZABLE_NOT_GENERATED'
            ELSE 'POLICY_REVIEW_REQUIRED'
        END AS lifecycle_status,
        CASE
            WHEN cdl.capitalizable_flag = 'Y'
                AND TRUNC(p.as_of_date) - TRUNC(cdl.prvdr_gl_date) >= p.grace_days
                AND COALESCE(e.posted_asset_count, 0) = 0
                AND COALESCE(e.has_capital_hold, 0) = 0
                THEN 1
            ELSE 0
        END AS is_capitalization_candidate
    FROM pjc_cost_dist_lines_all cdl
    CROSS JOIN params p
    LEFT JOIN cost_evidence e
        ON cdl.expenditure_item_id = e.expenditure_item_id
        AND cdl.line_num = e.line_num
)

SELECT
    expenditure_item_id,
    line_num,
    project_id,
    task_id,
    org_id,
    code_combination_id,
    prvdr_gl_date,
    capitalizable_flag,
    reversed_flag,
    denom_currency_code,
    denom_raw_cost,
    denom_burdened_cost,
    acct_currency_code,
    acct_raw_cost,
    acct_burdened_cost,
    as_of_date,
    age_days,
    asset_line_count,
    posted_asset_count,
    has_capital_hold,
    lifecycle_status,
    is_capitalization_candidate
FROM classified
