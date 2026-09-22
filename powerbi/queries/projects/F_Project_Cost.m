let
  Files = Table.SelectRows(
    Folder.Files("data"),
    each Text.StartsWith([Name], "project_cost_", Comparer.OrdinalIgnoreCase)
      and Text.Lower([Extension]) = ".csv"
  ),
  Sorted = Table.Sort(Files, {{"Name", Order.Ascending}}),
  Indexed = Table.AddIndexColumn(Sorted, "FileIndex", 0, 1, Int64.Type),
  Parsed = Table.AddColumn(
    Indexed,
    "CsvRows",
    each Csv.Document(
      [Content],
      [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    )
  ),
  HeaderOnce = Table.AddColumn(
    Parsed,
    "DataRows",
    each if [FileIndex] = 0 then [CsvRows] else Table.Skip([CsvRows], 1)
  ),
  Combined = Table.Combine(HeaderOnce[DataRows]),
  Promote = Table.PromoteHeaders(Combined, [PromoteAllScalars = true]),
  Types = Table.TransformColumnTypes(
    Promote,
    {
      {"EXPENDITURE_ITEM_ID", Int64.Type},
      {"LINE_NUM", Int64.Type},
      {"PROJECT_ID", Int64.Type},
      {"TASK_ID", Int64.Type},
      {"ORG_ID", Int64.Type},
      {"PRVDR_GL_DATE", type date},
      {"CAPITALIZABLE_FLAG", type text},
      {"REVERSED_FLAG", type text},
      {"DENOM_CURRENCY_CODE", type text},
      {"DENOM_RAW_COST", type number},
      {"DENOM_BURDENED_COST", type number},
      {"ACCT_CURRENCY_CODE", type text},
      {"ACCT_RAW_COST", type number},
      {"ACCT_BURDENED_COST", type number},
      {"CODE_COMBINATION_ID", Int64.Type},
      {"AS_OF_DATE", type date},
      {"AGE_DAYS", Int64.Type},
      {"ASSET_LINE_COUNT", Int64.Type},
      {"POSTED_ASSET_COUNT", Int64.Type},
      {"HAS_CAPITAL_HOLD", Int64.Type},
      {"LIFECYCLE_STATUS", type text},
      {"IS_CAPITALIZATION_CANDIDATE", Int64.Type}
    }
  )
in
  Types
