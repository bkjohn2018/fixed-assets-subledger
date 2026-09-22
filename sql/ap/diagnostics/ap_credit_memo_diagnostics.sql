-- Diagnostics: open credit memo analysis
-- Parameter: :as_of_date

WITH params AS (
    SELECT CAST(:as_of_date AS DATE) AS as_of_date
    FROM dual
),

open_credits AS (
    SELECT
        p.as_of_date,
        inv.vendor_id,
        inv.vendor_site_id,
        inv.org_id,
        inv.invoice_num,
        inv.invoice_date,
        ps.due_date,
        ps.amount_remaining,
        ps.payment_status_flag AS payment_status,
        ps.hold_flag,
        ps.iby_hold_reason,
        inv.invoice_type_lookup_code,
        inv.cancelled_date,
        inv.payment_status_flag AS invoice_payment_status,
        CASE WHEN inv.cancelled_date IS NOT NULL THEN 1 ELSE 0 END AS is_cancelled
    FROM ap_payment_schedules_all ps
    INNER JOIN ap_invoices_all inv
        ON ps.invoice_id = inv.invoice_id
    CROSS JOIN params p
    WHERE COALESCE(ps.amount_remaining, 0) <> 0
      AND UPPER(inv.invoice_type_lookup_code) LIKE '%CREDIT%'
)

SELECT
    oc.as_of_date,
    oc.vendor_id AS supplier_id,
    oc.vendor_site_id AS supplier_site_id,
    oc.org_id AS business_unit_id,
    oc.invoice_num,
    oc.invoice_date,
    oc.due_date,
    oc.amount_remaining,
    oc.payment_status,
    oc.hold_flag,
    oc.iby_hold_reason AS hold_reason,
    oc.invoice_type_lookup_code,
    CASE
        WHEN oc.is_cancelled = 1 THEN 'Cancelled/invalid credit memo'
        WHEN oc.hold_flag = 'Y' THEN 'Held credit memo'
        WHEN oc.amount_remaining < 0 THEN 'Open unapplied credit'
        ELSE 'Normal open credit'
    END AS possible_issue_classification,
    CASE
        WHEN oc.is_cancelled = 1 OR oc.hold_flag = 'Y' OR oc.amount_remaining <> 0
            THEN 'Needs AP review'
        ELSE 'Normal open credit'
    END AS review_flag
FROM open_credits oc
ORDER BY oc.amount_remaining
