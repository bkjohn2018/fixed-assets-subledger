SELECT
  "Asset"."Asset Id"                           AS ASSET_ID,
  "Asset Book"."Book Type Code"                AS BOOK_TYPE_CODE,
  "Asset Periods"."Period Counter"             AS PERIOD_COUNTER,
  "Asset Periods"."Period Name"                AS PERIOD_NAME,
  "Asset Balances"."Cost Beginning Balance"    AS COST_BEG,
  "Asset Balances Movements"."Additions"       AS ADDITIONS,
  "Asset Balances Movements"."Adjustments"     AS ADJUSTMENTS,
  "Asset Balances Movements"."Transfers Net"   AS TRANSFERS_NET,
  "Asset Balances Movements"."Retirements Cost" AS RETIREMENTS_COST,
  "Asset Balances Depreciation"."Depreciation for Period" AS DEPRN_PERIOD,
  "Asset Balances Depreciation"."Depreciation YTD"        AS DEPRN_YTD,
  "Asset Balances Depreciation"."Depreciation ITD"        AS DEPRN_ITD,
  "Asset Balances"."Net Book Value End"        AS NBV_END,
  "Asset"."Units"                               AS UNITS
FROM "Fixed Assets - Asset Balances Real Time"
WHERE "Asset Book"."Book Type Code" = @BOOK_TYPE_CODE
  AND "Asset Periods"."Period Name" = @PERIOD_NAME
