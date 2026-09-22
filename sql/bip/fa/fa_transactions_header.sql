SELECT
  "Asset Transaction"."Transaction Header Id"                    AS TRANSACTION_HEADER_ID,
  "Asset Transaction"."Transaction Type Code"                    AS TRANSACTION_TYPE_CODE,
  "Asset Transaction Dates"."Transaction Date"                   AS TRX_DATE,
  "Asset"."Asset Id"                                             AS ASSET_ID,
  "Asset"."Asset Number"                                         AS ASSET_NUMBER,
  "Asset Book"."Book Type Code"                                  AS BOOK_TYPE_CODE,
  "Asset Category"."Category Id"                                 AS CATEGORY_ID,
  SUM("Asset Transaction Amounts by Distribution"."Cost Delta")  AS COST_DELTA,
  SUM("Asset Transaction Amounts by Distribution"."Depreciation Reserve Delta") AS DEPRN_RESERVE_DELTA,
  SUM("Asset Transaction Amounts by Distribution"."Proceeds")    AS PROCEEDS,
  SUM("Asset Transaction Amounts by Distribution"."Gain or Loss") AS GAIN_LOSS,
  SUM("Asset Transaction Amounts by Distribution"."Units Delta") AS UNITS_DELTA
FROM "Fixed Assets - Asset Transactions Real Time"
WHERE "Asset Transaction"."Posted Flag" = 'Y'
  AND "Asset Book"."Book Type Code" = @BOOK_TYPE_CODE
  AND "Asset Transaction Dates"."Transaction Date" BETWEEN @START_DATE AND @END_DATE
GROUP BY
  "Asset Transaction"."Transaction Header Id",
  "Asset Transaction"."Transaction Type Code",
  "Asset Transaction Dates"."Transaction Date",
  "Asset"."Asset Id",
  "Asset"."Asset Number",
  "Asset Book"."Book Type Code",
  "Asset Category"."Category Id"
