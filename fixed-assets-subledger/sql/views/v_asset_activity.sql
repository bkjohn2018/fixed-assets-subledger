-- helper view: unified activity (do NOT use as authoritative source)
SELECT
  t.ASSET_ID,
  t.BOOK_TYPE_CODE,
  CAST(t.TRX_DATE AS DATE)       AS ACTIVITY_DATE,
  'TRANSACTION'                  AS ACTIVITY_CLASS,
  t.TRANSACTION_TYPE_CODE        AS ACTIVITY_TYPE,
  t.TRANSACTION_HEADER_ID        AS ACTIVITY_ID,
  t.COST_DELTA,
  t.DEPRN_RESERVE_DELTA,
  t.PROCEEDS,
  t.GAIN_LOSS,
  CAST(NULL AS NUMBER)           AS DEPRN_AMOUNT
FROM F_Asset_Transaction t
UNION ALL
SELECT
  d.ASSET_ID,
  d.BOOK_TYPE_CODE,
  /* map period to date in your D_Time as needed */ NULL AS ACTIVITY_DATE,
  'DEPRECIATION'                 AS ACTIVITY_CLASS,
  'DEPRN'                        AS ACTIVITY_TYPE,
  NULL                           AS ACTIVITY_ID,
  0, 0, 0, 0,
  d.DEPRN_AMOUNT
FROM F_Depreciation_Period d;
