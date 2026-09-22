-- Staging normalization: Oracle Projects cost distribution lines
-- Grain: EXPENDITURE_ITEM_ID + LINE_NUM

-- Preserve contract-compatible output column order.
-- noqa: disable=ST06
SELECT
    cdl.expenditure_item_id,
    cdl.line_num,
    cdl.project_id,
    cdl.task_id,
    cdl.org_id,
    cdl.raw_cost_dr_ccid AS code_combination_id,
    cdl.prvdr_gl_date,
    UPPER(TRIM(cdl.capitalizable_flag)) AS capitalizable_flag,
    UPPER(TRIM(COALESCE(cdl.reversed_flag, 'N'))) AS reversed_flag,
    cdl.denom_currency_code,
    cdl.denom_raw_cost,
    cdl.denom_burdened_cost,
    cdl.acct_currency_code,
    cdl.acct_raw_cost,
    cdl.acct_burdened_cost
FROM pjc_cost_dist_lines_all cdl
-- noqa: enable=ST06
