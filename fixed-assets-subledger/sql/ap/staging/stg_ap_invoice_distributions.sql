-- Staging: AP invoice distributions (one row per INVOICE_DISTRIBUTION_ID)
-- Source: AP_INVOICE_DISTRIBUTIONS_ALL (Oracle Fusion 26B)

WITH distributions AS (
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
        aid.final_match_flag,
        aid.po_distribution_id,
        aid.rcv_transaction_id,
        aid.quantity_invoiced,
        aid.unit_price,
        aid.reversal_flag,
        aid.pjc_project_id,
        aid.pjc_task_id,
        aid.pjc_expenditure_type_id,
        aid.pjc_expenditure_item_date,
        aid.pjc_organization_id,
        aid.pjc_billable_flag,
        aid.pa_addition_flag,
        aid.pa_cmt_xface_flag,
        aid.assets_addition_flag,
        aid.assets_tracking_flag,
        aid.asset_category_id,
        aid.accounting_event_id,
        aid.org_id,
        aid.creation_date,
        aid.created_by,
        aid.last_update_date,
        aid.last_updated_by,
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
        END AS is_asset_related,
        CASE
            WHEN aid.pa_addition_flag IS NOT NULL OR aid.assets_addition_flag IS NOT NULL THEN 1
            ELSE 0
        END AS is_capital_related
    FROM ap_invoice_distributions_all aid
)

SELECT
    invoice_distribution_id,
    invoice_id,
    distribution_line_number,
    line_type_lookup_code,
    amount,
    base_amount,
    accounting_date,
    period_name,
    dist_code_combination_id,
    match_status_flag,
    posted_flag,
    final_match_flag,
    po_distribution_id,
    rcv_transaction_id,
    quantity_invoiced,
    unit_price,
    reversal_flag,
    pjc_project_id,
    pjc_task_id,
    pjc_expenditure_type_id,
    pjc_expenditure_item_date,
    pjc_organization_id,
    pjc_billable_flag,
    pa_addition_flag,
    pa_cmt_xface_flag,
    assets_addition_flag,
    assets_tracking_flag,
    asset_category_id,
    accounting_event_id,
    org_id,
    creation_date,
    created_by,
    last_update_date,
    last_updated_by,
    is_project_related,
    is_po_matched,
    is_accounted,
    is_reversal,
    is_asset_related,
    is_capital_related
FROM distributions
