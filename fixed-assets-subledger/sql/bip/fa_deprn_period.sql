SELECT
  "Asset"."Asset Id"                            AS ASSET_ID,
  "Asset Book"."Book Type Code"                 AS BOOK_TYPE_CODE,
  "Asset Depreciation Period"."Period Counter"  AS PERIOD_COUNTER,
  "Asset Depreciation Period"."Period Name"     AS PERIOD_NAME,
  SUM("Asset Depreciation Amounts"."Depreciation Amount") AS DEPRN_AMOUNT,
  SUM("Asset Depreciation Amounts"."Bonus Depreciation")  AS DEPRN_BONUS,
  SUM("Asset Depreciation Amounts"."Catchup Depreciation") AS DEPRN_CATCHUP,
  SUM("Asset Depreciation Amounts"."Year to Date")   AS DEPRN_YTD,
  SUM("Asset Depreciation Amounts"."Inception to Date") AS DEPRN_ITD
FROM "Fixed Assets - Asset Depreciation Real Time"
WHERE "Asset Book"."Book Type Code" = @BOOK_TYPE_CODE
  AND "Asset Depreciation Period"."Period Name" = @PERIOD_NAME
GROUP BY
  "Asset"."Asset Id",
  "Asset Book"."Book Type Code",
  "Asset Depreciation Period"."Period Counter",
  "Asset Depreciation Period"."Period Name"
