SELECT
  "Asset Transaction"."Transaction Header Id"          AS TRANSACTION_HEADER_ID,
  "Asset Transaction Distribution"."Distribution Line Number" AS DISTRIBUTION_LINE_NUMBER,
  "Asset Transaction"."Transaction Type Code"          AS TRANSACTION_TYPE_CODE,
  "Asset Transaction Dates"."Transaction Date"         AS TRX_DATE,
  "Asset"."Asset Id"                                   AS ASSET_ID,
  "Asset"."Asset Number"                               AS ASSET_NUMBER,
  "Asset Book"."Book Type Code"                        AS BOOK_TYPE_CODE,
  "Asset Category"."Category Id"                       AS CATEGORY_ID,
  "Asset Transaction Amounts by Distribution"."Cost Delta"                 AS COST_DELTA,
  "Asset Transaction Amounts by Distribution"."Depreciation Reserve Delta" AS DEPRN_RESERVE_DELTA,
  "Asset Transaction Amounts by Distribution"."Proceeds"                   AS PROCEEDS,
  "Asset Transaction Amounts by Distribution"."Gain or Loss"               AS GAIN_LOSS,
  "Asset Transaction Amounts by Distribution"."Units Delta"                AS UNITS_DELTA,
  "Asset Transaction Distribution"."Code Combination Id"                   AS CODE_COMBINATION_ID
FROM "Fixed Assets - Asset Transactions Real Time"
WHERE "Asset Transaction"."Posted Flag" = 'Y'
  AND "Asset Book"."Book Type Code" = @BOOK_TYPE_CODE
  AND "Asset Transaction Dates"."Transaction Date" BETWEEN @START_DATE AND @END_DATE
