-- Diagnostics: distinct value profiles for AP lookup and status columns
-- Run in Fusion/BIP before finalizing CASE logic for credit memo and status flags

SELECT 'AP_INVOICES_ALL.INVOICE_TYPE_LOOKUP_CODE' AS profile_column,
    ai.invoice_type_lookup_code AS column_value,
    COUNT(*) AS row_count
FROM ap_invoices_all ai
GROUP BY ai.invoice_type_lookup_code

UNION ALL

SELECT 'AP_INVOICES_ALL.PAYMENT_STATUS_FLAG',
    ai.payment_status_flag,
    COUNT(*)
FROM ap_invoices_all ai
GROUP BY ai.payment_status_flag

UNION ALL

SELECT 'AP_PAYMENT_SCHEDULES_ALL.PAYMENT_STATUS_FLAG',
    ps.payment_status_flag,
    COUNT(*)
FROM ap_payment_schedules_all ps
GROUP BY ps.payment_status_flag

UNION ALL

SELECT 'AP_PAYMENT_SCHEDULES_ALL.HOLD_FLAG',
    ps.hold_flag,
    COUNT(*)
FROM ap_payment_schedules_all ps
GROUP BY ps.hold_flag

UNION ALL

SELECT 'AP_INVOICE_DISTRIBUTIONS_ALL.MATCH_STATUS_FLAG',
    aid.match_status_flag,
    COUNT(*)
FROM ap_invoice_distributions_all aid
GROUP BY aid.match_status_flag

UNION ALL

SELECT 'AP_INVOICE_DISTRIBUTIONS_ALL.POSTED_FLAG',
    aid.posted_flag,
    COUNT(*)
FROM ap_invoice_distributions_all aid
GROUP BY aid.posted_flag

UNION ALL

SELECT 'AP_INVOICE_DISTRIBUTIONS_ALL.PA_ADDITION_FLAG',
    aid.pa_addition_flag,
    COUNT(*)
FROM ap_invoice_distributions_all aid
GROUP BY aid.pa_addition_flag

UNION ALL

SELECT 'AP_INVOICE_DISTRIBUTIONS_ALL.ASSETS_ADDITION_FLAG',
    aid.assets_addition_flag,
    COUNT(*)
FROM ap_invoice_distributions_all aid
GROUP BY aid.assets_addition_flag

ORDER BY profile_column, column_value
