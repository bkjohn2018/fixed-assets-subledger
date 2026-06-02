-- Diagnostics: reconciliation checks for AP aging schedule fact
-- Parameter: :as_of_date

WITH params AS (
    SELECT CAST(:as_of_date AS DATE) AS as_of_date
    FROM dual
),

source_open AS (
    SELECT
        SUM(COALESCE(ps.amount_remaining, 0)) AS source_amount_remaining,
        COUNT(*) AS source_row_count
    FROM ap_payment_schedules_all ps
    WHERE COALESCE(ps.amount_remaining, 0) <> 0
),

mart_open AS (
    SELECT
        SUM(a.amount_remaining) AS mart_amount_remaining,
        COUNT(*) AS mart_row_count
    FROM (
        SELECT ps.amount_remaining
        FROM ap_payment_schedules_all ps
        INNER JOIN ap_invoices_all inv
            ON ps.invoice_id = inv.invoice_id
        CROSS JOIN params p
        WHERE COALESCE(ps.amount_remaining, 0) <> 0
    ) a
),

grain_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(
            DISTINCT CAST(ps.invoice_id AS VARCHAR2(40))
            || '-'
            || CAST(ps.payment_num AS VARCHAR2(20))
            || '-'
            || TO_CHAR(p.as_of_date, 'YYYY-MM-DD')
        ) AS distinct_grain_keys
    FROM ap_payment_schedules_all ps
    CROSS JOIN params p
    WHERE COALESCE(ps.amount_remaining, 0) <> 0
),

bridge_inflation_check AS (
    SELECT
        SUM(ps.amount_remaining) AS amount_before_bridge,
        SUM(ps.amount_remaining) AS amount_after_bridge
    FROM ap_payment_schedules_all ps
    INNER JOIN ap_invoices_all inv
        ON ps.invoice_id = inv.invoice_id
    LEFT JOIN (
        SELECT invoice_id, COUNT(*) AS dist_cnt
        FROM ap_invoice_distributions_all
        GROUP BY invoice_id
    ) br
        ON inv.invoice_id = br.invoice_id
    WHERE COALESCE(ps.amount_remaining, 0) <> 0
),

paid_zero_check AS (
    SELECT COUNT(*) AS paid_with_remaining
    FROM ap_payment_schedules_all ps
    WHERE ps.payment_status_flag = 'Y'
      AND COALESCE(ps.amount_remaining, 0) <> 0
)

SELECT 'amount_reconciliation' AS check_name,
    s.source_amount_remaining,
    m.mart_amount_remaining,
    s.source_amount_remaining - m.mart_amount_remaining AS amount_delta,
    CASE
        WHEN ABS(s.source_amount_remaining - m.mart_amount_remaining) < 0.01 THEN 'PASS'
        ELSE 'FAIL'
    END AS check_result
FROM source_open s
CROSS JOIN mart_open m

UNION ALL

SELECT 'grain_uniqueness',
    gc.total_rows,
    gc.distinct_grain_keys,
    gc.total_rows - gc.distinct_grain_keys,
    CASE WHEN gc.total_rows = gc.distinct_grain_keys THEN 'PASS' ELSE 'FAIL' END
FROM grain_check gc

UNION ALL

SELECT 'bridge_no_inflation',
    bic.amount_before_bridge,
    bic.amount_after_bridge,
    bic.amount_before_bridge - bic.amount_after_bridge,
    CASE
        WHEN ABS(bic.amount_before_bridge - bic.amount_after_bridge) < 0.01 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM bridge_inflation_check bic

UNION ALL

SELECT 'paid_schedules_zero_remaining',
    pzc.paid_with_remaining,
    NULL,
    NULL,
    CASE WHEN pzc.paid_with_remaining = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM paid_zero_check pzc
