let
  Files = Table.SelectRows(
    Folder.Files("data"),
    each Text.StartsWith([Name], "project_asset_line_", Comparer.OrdinalIgnoreCase)
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
      {"PROJECT_ASSET_LINE_DETAIL_ID", Int64.Type},
      {"PROJECT_ASSET_ID", Int64.Type},
      {"PROJECT_ID", Int64.Type},
      {"TASK_ID", Int64.Type},
      {"ORG_ID", Int64.Type},
      {"LINE_TYPE", type text},
      {"DESCRIPTION", type text},
      {"ORIGINAL_ASSET_COST", type number},
      {"CURRENT_ASSET_COST", type number},
      {"CIP_CCID", Int64.Type},
      {"TRANSFER_STATUS_CODE", type text},
      {"TRANSFER_REJECTION_REASON", type text},
      {"UNASSIGNED_LINE_FLAG", type text},
      {"REV_PROJ_ASSET_LINE_ID", Int64.Type},
      {"CREATION_DATE", type datetime},
      {"PROJECT_ASSET_NAME", type text},
      {"BOOK_TYPE_CODE", type text},
      {"DATE_PLACED_IN_SERVICE", type date},
      {"CAPITALIZED_FLAG", type text},
      {"CAPITALIZED_DATE", type date},
      {"CAPITAL_HOLD_FLAG", type text},
      {"FA_ASSET_ID", Int64.Type}
    }
  )
in
  Types
