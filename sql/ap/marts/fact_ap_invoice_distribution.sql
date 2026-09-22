-- Mart: AP invoice distribution fact (drill-through)
-- Grain: INVOICE_DISTRIBUTION_ID

WITH params AS (
    SELECT CAST(:as_of_date AS DATE) AS as_of_date
    FROM dual
),

distributions AS (
    SELECT
        aid.invoice_distribution_id,
        aid.invoice_id,
        aid.distribution_line_number,
        aid.line_type_lookup_code,
        aid.amount,
        aid.base_amount,
        aid.accounting_date,
        aid.period_name,
        aid.dist_code_combination_id,
        aid.match_status_flag,
        aid.posted_flag,
        aid.po_distribution_id,
        aid.rcv_transaction_id,
        aid.pjc_project_id,
        aid.pjc_task_id,
        aid.pjc_expenditure_type_id,
        aid.pjc_expenditure_item_date,
        aid.pjc_organization_id,
        aid.pjc_billable_flag,
        aid.pa_addition_flag,
        aid.assets_addition_flag,
        aid.assets_tracking_flag,
        aid.asset_category_id,
        aid.org_id,
        CASE
            WHEN aid.pjc_project_id IS NOT NULL OR aid.pa_addition_flag IS NOT NULL THEN 1
            ELSE 0
        END AS is_project_related,
        CASE WHEN aid.po_distribution_id IS NOT NULL THEN 1 ELSE 0 END AS is_po_matched,
        CASE WHEN aid.posted_flag = 'Y' THEN 1 ELSE 0 END AS is_accounted,
        CASE WHEN aid.reversal_flag = 'Y' THEN 1 ELSE 0 END AS is_reversal,
        CASE
            WHEN aid.assets_addition_flag IS NOT NULL OR aid.assets_tracking_flag = 'Y' THEN 1
            ELSE 0
        END AS is_asset_related
    FROM ap_invoice_distributions_all aid
),

invoices AS (
    SELECT
        ai.invoice_id,
        ai.vendor_id,
        ai.invoice_num,
        ai.invoice_date,
        ai.org_id
    FROM ap_invoices_all ai
)

SELECT
    p.as_of_date,
    d.invoice_distribution_id,
    d.invoice_id,
    d.distribution_line_number,
    d.line_type_lookup_code,
    d.amount,
    d.base_amount,
    d.accounting_date,
    d.period_name,
    d.dist_code_combination_id,
    d.match_status_flag,
    d.posted_flag,
    d.po_distribution_id,
    d.rcv_transaction_id,
    d.pjc_project_id,
    d.pjc_task_id,
    d.pjc_expenditure_type_id,
    d.pjc_expenditure_item_date,
    d.pjc_organization_id,
    d.pjc_billable_flag,
    d.pa_addition_flag,
    d.assets_addition_flag,
    d.assets_tracking_flag,
    d.asset_category_id,
    d.is_project_related,
    d.is_po_matched,
    d.is_accounted,
    d.is_reversal,
    d.is_asset_related,
    inv.vendor_id,
    inv.invoice_num,
    inv.invoice_date,
    d.org_id
FROM distributions d
INNER JOIN invoices inv
    ON d.invoice_id = inv.invoice_id
CROSS JOIN params p
