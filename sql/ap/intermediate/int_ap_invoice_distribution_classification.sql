-- Intermediate: invoice-level distribution classification bridge
-- Grain: one row per INVOICE_ID

WITH params AS (
    SELECT CAST(:as_of_date AS DATE) AS as_of_date
    FROM dual
),

distributions AS (
    SELECT
        aid.invoice_distribution_id,
        aid.invoice_id,
        aid.amount,
        aid.pjc_project_id,
        aid.pa_addition_flag,
        aid.po_distribution_id,
        aid.posted_flag,
        aid.reversal_flag,
        aid.assets_addition_flag,
        aid.assets_tracking_flag,
        CASE
            WHEN aid.pjc_project_id IS NOT NULL OR aid.pa_addition_flag IS NOT NULL THEN 1
            ELSE 0
        END AS is_project_related,
        CASE
            WHEN aid.pa_addition_flag IS NOT NULL OR aid.assets_addition_flag IS NOT NULL THEN 1
            ELSE 0
        END AS is_capital_related,
        CASE WHEN aid.po_distribution_id IS NOT NULL THEN 1 ELSE 0 END AS is_po_matched,
        CASE WHEN aid.posted_flag = 'Y' THEN 1 ELSE 0 END AS is_accounted,
        CASE WHEN aid.reversal_flag = 'Y' THEN 1 ELSE 0 END AS is_reversal,
        CASE
            WHEN aid.assets_addition_flag IS NOT NULL OR aid.assets_tracking_flag = 'Y' THEN 1
            ELSE 0
        END AS is_asset_related
    FROM ap_invoice_distributions_all aid
),

invoice_classification AS (
    SELECT
        d.invoice_id,
        MAX(d.is_project_related) AS has_project_distribution,
        MAX(d.is_capital_related) AS has_capital_project_distribution,
        MAX(d.is_po_matched) AS has_po_matched_distribution,
        MAX(CASE WHEN d.is_accounted = 0 THEN 1 ELSE 0 END) AS has_unaccounted_distribution,
        MAX(d.is_asset_related) AS has_asset_related_distribution,
        MAX(d.is_reversal) AS has_reversal_distribution,
        COUNT(*) AS distribution_count,
        SUM(COALESCE(d.amount, 0)) AS distribution_total_amount,
        COUNT(DISTINCT d.pjc_project_id) AS project_count,
        SUM(d.is_po_matched) AS po_distribution_count,
        SUM(d.is_accounted) AS accounted_distribution_count,
        SUM(CASE WHEN d.is_accounted = 0 THEN 1 ELSE 0 END) AS unaccounted_distribution_count
    FROM distributions d
    GROUP BY d.invoice_id
)

SELECT
    p.as_of_date,
    ic.invoice_id,
    ic.has_project_distribution,
    ic.has_capital_project_distribution,
    ic.has_po_matched_distribution,
    ic.has_unaccounted_distribution,
    ic.has_asset_related_distribution,
    ic.has_reversal_distribution,
    ic.distribution_count,
    ic.distribution_total_amount,
    ic.project_count,
    ic.po_distribution_count,
    ic.accounted_distribution_count,
    ic.unaccounted_distribution_count
FROM invoice_classification ic
CROSS JOIN params p
