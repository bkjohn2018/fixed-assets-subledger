let
  Source = Csv.Document(
    File.Contents("data/ap_invoice_distribution_*.csv"),
    [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
  ),
  Promote = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
  Types = Table.TransformColumnTypes(
    Promote,
    {
      {"AS_OF_DATE", type date},
      {"INVOICE_DISTRIBUTION_ID", Int64.Type},
      {"INVOICE_ID", Int64.Type},
      {"DISTRIBUTION_LINE_NUMBER", Int64.Type},
      {"LINE_TYPE_LOOKUP_CODE", type text},
      {"AMOUNT", type number},
      {"BASE_AMOUNT", type number},
      {"ACCOUNTING_DATE", type date},
      {"PERIOD_NAME", type text},
      {"DIST_CODE_COMBINATION_ID", Int64.Type},
      {"MATCH_STATUS_FLAG", type text},
      {"POSTED_FLAG", type text},
      {"PO_DISTRIBUTION_ID", Int64.Type},
      {"RCV_TRANSACTION_ID", Int64.Type},
      {"PJC_PROJECT_ID", Int64.Type},
      {"PJC_TASK_ID", Int64.Type},
      {"PJC_EXPENDITURE_TYPE_ID", Int64.Type},
      {"PJC_EXPENDITURE_ITEM_DATE", type date},
      {"PJC_ORGANIZATION_ID", Int64.Type},
      {"PJC_BILLABLE_FLAG", type text},
      {"PA_ADDITION_FLAG", type text},
      {"ASSETS_ADDITION_FLAG", type text},
      {"ASSETS_TRACKING_FLAG", type text},
      {"ASSET_CATEGORY_ID", Int64.Type},
      {"IS_PROJECT_RELATED", Int64.Type},
      {"IS_PO_MATCHED", Int64.Type},
      {"IS_ACCOUNTED", Int64.Type},
      {"IS_REVERSAL", Int64.Type},
      {"IS_ASSET_RELATED", Int64.Type},
      {"VENDOR_ID", Int64.Type},
      {"INVOICE_NUM", type text},
      {"INVOICE_DATE", type date},
      {"ORG_ID", Int64.Type}
    }
  )
in
  Types
