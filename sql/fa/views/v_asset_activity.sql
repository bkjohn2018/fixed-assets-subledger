-- convenience view (do not treat as authoritative)
SELECT
    t.asset_id,
    t.book_type_code,
    CAST(t.trx_date AS DATE) AS activity_date,
    'TRANSACTION' AS activity_class,
    t.transaction_type_code AS activity_type,
    t.transaction_header_id AS activity_id,
    t.cost_delta,
    t.deprn_reserve_delta,
    t.proceeds,
    t.gain_loss,
    CAST(NULL AS NUMBER) AS deprn_amount
FROM f_asset_transaction t
UNION ALL
SELECT
    d.asset_id,
    d.book_type_code,
    NULL AS activity_date,
    'DEPRECIATION' AS activity_class,
    'DEPRN' AS activity_type,
    NULL AS activity_id,
    0 AS cost_delta,
    0 AS deprn_reserve_delta,
    0 AS proceeds,
    0 AS gain_loss,
    d.deprn_amount AS depreciation_amount
FROM f_depreciation_period d;
