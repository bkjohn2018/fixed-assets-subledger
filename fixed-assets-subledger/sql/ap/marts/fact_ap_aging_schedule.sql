-- Mart: AP aging schedule fact
-- Grain: INVOICE_ID + PAYMENT_NUM + AS_OF_DATE

WITH params AS (
    SELECT CAST(:as_of_date AS DATE) AS as_of_date
    FROM dual
),

payment_schedules AS (
    SELECT
        ps.invoice_id,
        ps.payment_num,
        ps.org_id,
        ps.due_date,
        ps.gross_amount,
        ps.amount_remaining,
        ps.payment_status_flag AS schedule_payment_status_flag,
        ps.hold_flag,
        ps.held_by,
        ps.hold_date,
        ps.iby_hold_reason,
        ps.payment_method_lookup_code,
        ps.payment_method_code
    FROM ap_payment_schedules_all ps
    WHERE COALESCE(ps.amount_remaining, 0) <> 0
),

invoices AS (
    SELECT
        ai.invoice_id,
        ai.vendor_id,
        ai.vendor_site_id,
        ai.invoice_num,
        ai.invoice_date,
        ai.invoice_received_date,
        ai.invoice_type_lookup_code,
        ai.invoice_amount,
        ai.amount_paid,
        ai.payment_amount_total,
        ai.invoice_currency_code,
        ai.payment_currency_code,
        ai.payment_status_flag AS invoice_payment_status_flag,
        ai.terms_id,
        ai.terms_date,
        ai.source,
        ai.po_header_id,
        ai.pay_group_lookup_code,
        ai.cancelled_date,
        CASE WHEN UPPER(ai.invoice_type_lookup_code) LIKE '%CREDIT%' THEN 1 ELSE 0 END AS is_credit_memo,
        CASE WHEN UPPER(ai.invoice_type_lookup_code) LIKE '%DEBIT%' THEN 1 ELSE 0 END AS is_debit_memo,
        CASE WHEN UPPER(ai.invoice_type_lookup_code) LIKE '%PREPAY%' THEN 1 ELSE 0 END AS is_prepayment,
        CASE WHEN ai.cancelled_date IS NOT NULL THEN 1 ELSE 0 END AS is_cancelled
    FROM ap_invoices_all ai
),

distribution_bridge AS (
    SELECT
        aid.invoice_id,
        MAX(
            CASE
                WHEN aid.pjc_project_id IS NOT NULL OR aid.pa_addition_flag IS NOT NULL THEN 1
                ELSE 0
            END
        ) AS has_project_distribution,
        MAX(
            CASE
                WHEN aid.pa_addition_flag IS NOT NULL OR aid.assets_addition_flag IS NOT NULL THEN 1
                ELSE 0
            END
        ) AS has_capital_project_distribution,
        MAX(CASE WHEN aid.po_distribution_id IS NOT NULL THEN 1 ELSE 0 END) AS has_po_matched_distribution,
        MAX(CASE WHEN COALESCE(aid.posted_flag, 'N') <> 'Y' THEN 1 ELSE 0 END) AS has_unaccounted_distribution,
        MAX(
            CASE
                WHEN aid.assets_addition_flag IS NOT NULL OR aid.assets_tracking_flag = 'Y' THEN 1
                ELSE 0
            END
        ) AS has_asset_related_distribution,
        MAX(CASE WHEN aid.reversal_flag = 'Y' THEN 1 ELSE 0 END) AS has_reversal_distribution,
        COUNT(*) AS distribution_count,
        SUM(COALESCE(aid.amount, 0)) AS distribution_total_amount,
        COUNT(DISTINCT aid.pjc_project_id) AS project_count,
        SUM(CASE WHEN aid.po_distribution_id IS NOT NULL THEN 1 ELSE 0 END) AS po_distribution_count
    FROM ap_invoice_distributions_all aid
    GROUP BY aid.invoice_id
),

aging AS (
    SELECT
        p.as_of_date,
        CAST(ps.invoice_id AS VARCHAR2(40)) || '-' || CAST(ps.payment_num AS VARCHAR2(20)) AS schedule_key,
        ps.invoice_id,
        ps.payment_num,
        ps.org_id,
        inv.vendor_id,
        inv.vendor_site_id,
        inv.invoice_num,
        inv.invoice_date,
        inv.invoice_received_date,
        ps.due_date,
        inv.terms_id,
        inv.terms_date,
        inv.invoice_type_lookup_code,
        inv.invoice_currency_code,
        inv.payment_currency_code,
        ps.payment_method_code,
        ps.payment_method_lookup_code,
        inv.pay_group_lookup_code,
        inv.source,
        inv.po_header_id,
        ps.schedule_payment_status_flag AS payment_status_flag_schedule,
        inv.invoice_payment_status_flag AS payment_status_flag_invoice,
        ps.hold_flag,
        ps.held_by,
        ps.hold_date,
        ps.iby_hold_reason,
        ps.gross_amount,
        ps.amount_remaining,
        ps.amount_remaining AS open_amount,
        inv.invoice_amount,
        inv.amount_paid,
        inv.payment_amount_total,
        TRUNC(p.as_of_date) - TRUNC(ps.due_date) AS days_past_due,
        CASE
            WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) <= 0 THEN 'Current / Not Yet Due'
            WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) BETWEEN 1 AND 30 THEN '1-30 Past Due'
            WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) BETWEEN 31 AND 60 THEN '31-60 Past Due'
            WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) BETWEEN 61 AND 90 THEN '61-90 Past Due'
            ELSE '90+ Past Due'
        END AS aging_bucket,
        CASE
            WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) > 0 THEN 'Past Due'
            WHEN TRUNC(ps.due_date) = TRUNC(p.as_of_date) THEN 'Due Today'
            ELSE 'Forward'
        END AS aging_direction,
        CASE WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) <= 0 THEN 1 ELSE 0 END AS is_current,
        CASE WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) > 0 THEN 1 ELSE 0 END AS is_past_due,
        CASE
            WHEN TRUNC(ps.due_date) BETWEEN TRUNC(p.as_of_date) + 1 AND TRUNC(p.as_of_date) + 7 THEN 1
            ELSE 0
        END AS is_due_next_7_days,
        CASE
            WHEN TRUNC(ps.due_date) BETWEEN TRUNC(p.as_of_date) + 1 AND TRUNC(p.as_of_date) + 30 THEN 1
            ELSE 0
        END AS is_due_next_30_days,
        inv.is_credit_memo,
        inv.is_debit_memo,
        inv.is_prepayment,
        inv.is_cancelled,
        CASE WHEN ps.hold_flag = 'Y' THEN 1 ELSE 0 END AS is_on_hold,
        CASE WHEN ps.schedule_payment_status_flag = 'Y' THEN 1 ELSE 0 END AS is_fully_paid,
        CASE WHEN ps.schedule_payment_status_flag = 'N' THEN 1 ELSE 0 END AS is_unpaid,
        CASE WHEN ps.schedule_payment_status_flag = 'P' THEN 1 ELSE 0 END AS is_partially_paid,
        COALESCE(br.has_project_distribution, 0) AS has_project_distribution,
        COALESCE(br.has_capital_project_distribution, 0) AS has_capital_project_distribution,
        COALESCE(br.has_po_matched_distribution, 0) AS has_po_matched_distribution,
        COALESCE(br.has_unaccounted_distribution, 0) AS has_unaccounted_distribution,
        COALESCE(br.has_asset_related_distribution, 0) AS has_asset_related_distribution,
        COALESCE(br.has_reversal_distribution, 0) AS has_reversal_distribution,
        br.distribution_count,
        br.distribution_total_amount,
        br.project_count,
        br.po_distribution_count
    FROM payment_schedules ps
    INNER JOIN invoices inv
        ON ps.invoice_id = inv.invoice_id
    LEFT JOIN distribution_bridge br
        ON inv.invoice_id = br.invoice_id
    CROSS JOIN params p
)

SELECT
    as_of_date,
    schedule_key,
    invoice_id,
    payment_num,
    org_id,
    vendor_id,
    vendor_site_id,
    invoice_num,
    invoice_date,
    invoice_received_date,
    due_date,
    terms_id,
    terms_date,
    invoice_type_lookup_code,
    invoice_currency_code,
    payment_currency_code,
    payment_method_code,
    payment_method_lookup_code,
    pay_group_lookup_code,
    source,
    po_header_id,
    payment_status_flag_schedule,
    payment_status_flag_invoice,
    hold_flag,
    held_by,
    hold_date,
    iby_hold_reason,
    gross_amount,
    amount_remaining,
    open_amount,
    invoice_amount,
    amount_paid,
    payment_amount_total,
    days_past_due,
    aging_bucket,
    aging_direction,
    is_current,
    is_past_due,
    is_due_next_7_days,
    is_due_next_30_days,
    is_credit_memo,
    is_debit_memo,
    is_prepayment,
    is_cancelled,
    is_on_hold,
    is_fully_paid,
    is_unpaid,
    is_partially_paid,
    has_project_distribution,
    has_capital_project_distribution,
    has_po_matched_distribution,
    has_unaccounted_distribution,
    has_asset_related_distribution,
    has_reversal_distribution,
    distribution_count,
    distribution_total_amount,
    project_count,
    po_distribution_count
FROM aging
