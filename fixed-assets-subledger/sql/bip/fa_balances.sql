SELECT
  "Asset"."Asset Id"                           AS ASSET_ID,
  "Asset Book"."Book Type Code"                AS BOOK_TYPE_CODE,
  "Asset Periods"."Period Counter"             AS PERIOD_COUNTER,
  "Asset Periods"."Period Name"                AS PERIOD_NAME,
  SUM("Asset Balances"."Cost Beginning Balance")    AS COST_BEG,
  SUM("Asset Balances Movements"."Additions")       AS ADDITIONS,
  SUM("Asset Balances Movements"."Adjustments")     AS ADJUSTMENTS,
  SUM("Asset Balances Movements"."Transfers Net")   AS TRANSFERS_NET,
  SUM("Asset Balances Movements"."Retirements Cost") AS RETIREMENTS_COST,
  SUM("Asset Balances Depreciation"."Depreciation for Period") AS DEPRN_PERIOD,
  SUM("Asset Balances Depreciation"."Depreciation YTD")        AS DEPRN_YTD,
  SUM("Asset Balances Depreciation"."Depreciation ITD")        AS DEPRN_ITD,
  SUM("Asset Balances"."Net Book Value End")        AS NBV_END,
  MAX("Asset"."Units")                               AS UNITS
FROM "Fixed Assets - Asset Balances Real Time"
WHERE "Asset Book"."Book Type Code" = @BOOK_TYPE_CODE
  AND "Asset Periods"."Period Name" = @PERIOD_NAME
GROUP BY
  "Asset"."Asset Id",
  "Asset Book"."Book Type Code",
  "Asset Periods"."Period Counter",
  "Asset Periods"."Period Name"
