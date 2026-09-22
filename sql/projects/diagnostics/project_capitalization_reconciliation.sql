-- Diagnostic: source-to-mart amounts and posted evidence by project asset line.
-- Review differences; adjustments, reversals, and splits can create legitimate variances.

WITH source_cost AS (
    SELECT
        acct_currency_code AS currency_code,
        raw_cost_dr_ccid AS code_combination_id,
        SUM(COALESCE(acct_raw_cost, 0)) AS source_amount
    FROM pjc_cost_dist_lines_all
    GROUP BY acct_currency_code, raw_cost_dr_ccid
),

mart_cost AS (
    SELECT
        acct_currency_code AS currency_code,
        code_combination_id,
        SUM(COALESCE(acct_raw_cost, 0)) AS mart_amount
    FROM fact_project_cost
    GROUP BY acct_currency_code, code_combination_id
)

SELECT
    COALESCE(s.currency_code, m.currency_code) AS currency_code,
    COALESCE(s.code_combination_id, m.code_combination_id) AS code_combination_id,
    COALESCE(s.source_amount, 0) AS source_amount,
    COALESCE(m.mart_amount, 0) AS mart_amount,
    COALESCE(m.mart_amount, 0) - COALESCE(s.source_amount, 0) AS difference_amount
FROM source_cost s
FULL OUTER JOIN mart_cost m
    ON s.currency_code = m.currency_code
    AND (
        s.code_combination_id = m.code_combination_id
        OR (s.code_combination_id IS NULL AND m.code_combination_id IS NULL)
    );

WITH source_posted AS (
    SELECT
        project_asset_line_id,
        SUM(COALESCE(fixed_assets_cost, 0)) AS source_posted_cost
    FROM fa_asset_invoices
    WHERE project_asset_line_id IS NOT NULL
    GROUP BY project_asset_line_id
)

SELECT
    COALESCE(s.project_asset_line_id, f.project_asset_line_id) AS project_asset_line_id,
    COALESCE(s.source_posted_cost, 0) AS source_posted_cost,
    COALESCE(f.posted_fixed_assets_cost, 0) AS mart_posted_cost,
    COALESCE(f.posted_fixed_assets_cost, 0) - COALESCE(s.source_posted_cost, 0) AS difference_amount,
    f.current_asset_cost - COALESCE(f.posted_fixed_assets_cost, 0) AS project_to_posted_variance
FROM source_posted s
FULL OUTER JOIN fact_project_capitalization_status f
    ON s.project_asset_line_id = f.project_asset_line_id
WHERE COALESCE(f.posted_fixed_assets_cost, 0) <> COALESCE(s.source_posted_cost, 0)
    OR COALESCE(f.current_asset_cost, 0) <> COALESCE(f.posted_fixed_assets_cost, 0);
