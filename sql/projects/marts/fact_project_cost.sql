-- Mart: F_Project_Cost
-- Grain and output columns match contracts/projects/project_cost.yml.

SELECT
    c.expenditure_item_id,
    c.line_num,
    c.project_id,
    c.task_id,
    c.org_id,
    c.code_combination_id,
    c.prvdr_gl_date,
    c.capitalizable_flag,
    c.reversed_flag,
    c.denom_currency_code,
    c.denom_raw_cost,
    c.denom_burdened_cost,
    c.acct_currency_code,
    c.acct_raw_cost,
    c.acct_burdened_cost,
    x.as_of_date,
    x.age_days,
    x.asset_line_count,
    x.posted_asset_count,
    x.has_capital_hold,
    x.lifecycle_status,
    x.is_capitalization_candidate
FROM stg_project_cost c
INNER JOIN int_project_capitalization_classification x
    ON c.expenditure_item_id = x.expenditure_item_id
    AND c.line_num = x.line_num
    AND x.record_grain = 'COST'
