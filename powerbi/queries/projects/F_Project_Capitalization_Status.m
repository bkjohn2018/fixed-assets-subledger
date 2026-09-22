let
  Files = Table.SelectRows(
    Folder.Files("data"),
    each Text.StartsWith([Name], "project_capitalization_status_", Comparer.OrdinalIgnoreCase)
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
      {"PROJECT_ASSET_LINE_ID", Int64.Type},
      {"AS_OF_DATE", type date},
      {"PROJECT_ASSET_ID", Int64.Type},
      {"PROJECT_ID", Int64.Type},
      {"TASK_ID", Int64.Type},
      {"CURRENT_ASSET_COST", type number},
      {"TRANSFER_STATUS_CODE", type text},
      {"TRANSFER_REJECTION_REASON", type text},
      {"CAPITALIZABLE_FLAG", type text},
      {"CAPITAL_HOLD_FLAG", type text},
      {"AGE_DAYS", Int64.Type},
      {"MASS_ADDITION_COUNT", Int64.Type},
      {"MASS_ADDITION_STATUS_PROFILE", type text},
      {"POSTED_SOURCE_LINE_COUNT", Int64.Type},
      {"POSTED_FIXED_ASSETS_COST", type number},
      {"FA_ASSET_ID", Int64.Type},
      {"LIFECYCLE_STATUS", type text},
      {"IS_CAPITALIZATION_CANDIDATE", Int64.Type}
    }
  )
in
  Types
