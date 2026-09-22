let
  Files = Table.SelectRows(
    Folder.Files("data"),
    each Text.StartsWith([Name], "project_cost_to_asset_line_", Comparer.OrdinalIgnoreCase)
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
      {"PROJ_ASSET_LINE_DTL_UNIQ_ID", Int64.Type},
      {"PROJECT_ASSET_LINE_DETAIL_ID", Int64.Type},
      {"PROJECT_ASSET_LINE_ID", Int64.Type},
      {"EXPENDITURE_ITEM_ID", Int64.Type},
      {"LINE_NUM", Int64.Type},
      {"PROJECT_ID", Int64.Type},
      {"TASK_ID", Int64.Type},
      {"DETAIL_REVERSAL_FLAG", type text},
      {"COST_TO_ASSET_LINE_FANOUT", Int64.Type},
      {"ASSET_LINE_TO_COST_FANIN", Int64.Type},
      {"IS_SPLIT_FANOUT", Int64.Type}
    }
  )
in
  Types
