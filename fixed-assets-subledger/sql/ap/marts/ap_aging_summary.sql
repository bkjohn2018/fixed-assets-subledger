-- Mart: Executive AP aging summary (aggregated from schedule fact logic)
-- Use for validation and ad hoc reporting; Power BI can replicate via DAX

WITH params AS (
    SELECT CAST(:as_of_date AS DATE) AS as_of_date
    FROM dual
),

schedule_fact AS (
    SELECT
        a.as_of_date,
        a.aging_bucket,
        a.amount_remaining,
        a.invoice_id,
        a.vendor_id,
        a.is_on_hold,
        a.is_credit_memo,
        a.has_project_distribution
    FROM (
        SELECT
            p.as_of_date,
            ps.invoice_id,
            ps.payment_num,
            inv.vendor_id,
            ps.amount_remaining,
            ps.hold_flag,
            CASE WHEN ps.hold_flag = 'Y' THEN 1 ELSE 0 END AS is_on_hold,
            CASE WHEN UPPER(inv.invoice_type_lookup_code) LIKE '%CREDIT%' THEN 1 ELSE 0 END AS is_credit_memo,
            CASE
                WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) <= 0 THEN 'Current / Not Yet Due'
                WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) BETWEEN 1 AND 30 THEN '1-30 Past Due'
                WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) BETWEEN 31 AND 60 THEN '31-60 Past Due'
                WHEN TRUNC(p.as_of_date) - TRUNC(ps.due_date) BETWEEN 61 AND 90 THEN '61-90 Past Due'
                ELSE '90+ Past Due'
            END AS aging_bucket,
            COALESCE(
                (
                    SELECT MAX(
                        CASE
                            WHEN aid.pjc_project_id IS NOT NULL OR aid.pa_addition_flag IS NOT NULL THEN 1
                            ELSE 0
                        END
                    )
                    FROM ap_invoice_distributions_all aid
                    WHERE aid.invoice_id = ps.invoice_id
                ),
                0
            ) AS has_project_distribution
        FROM ap_payment_schedules_all ps
        INNER JOIN ap_invoices_all inv
            ON ps.invoice_id = inv.invoice_id
        CROSS JOIN params p
        WHERE COALESCE(ps.amount_remaining, 0) <> 0
    ) a
)

SELECT
    sf.as_of_date,
    sf.aging_bucket,
    SUM(sf.amount_remaining) AS open_amount,
    COUNT(DISTINCT sf.invoice_id) AS invoice_count,
    COUNT(DISTINCT sf.vendor_id) AS supplier_count,
    SUM(CASE WHEN sf.is_on_hold = 1 THEN sf.amount_remaining ELSE 0 END) AS held_amount,
    SUM(CASE WHEN sf.is_credit_memo = 1 THEN sf.amount_remaining ELSE 0 END) AS credit_memo_amount,
    SUM(
        CASE WHEN sf.has_project_distribution = 1 THEN sf.amount_remaining ELSE 0 END
    ) AS project_related_amount
FROM schedule_fact sf
GROUP BY sf.as_of_date, sf.aging_bucket
ORDER BY sf.aging_bucket
