let
  Source = Csv.Document(File.Contents("data/fa_transactions_*.csv"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
  Promote = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
  Types = Table.TransformColumnTypes(Promote,{
    {"TRANSACTION_HEADER_ID", Int64.Type}, {"TRANSACTION_TYPE_CODE", type text},
    {"TRX_DATE", type date}, {"ASSET_ID", Int64.Type}, {"ASSET_NUMBER", type text},
    {"BOOK_TYPE_CODE", type text}, {"CATEGORY_ID", Int64.Type}, {"COST_DELTA", type number},
    {"DEPRN_RESERVE_DELTA", type number}, {"PROCEEDS", type number}, {"GAIN_LOSS", type number},
    {"UNITS_DELTA", type number}, {"CODE_COMBINATION_ID", Int64.Type}})
in  Types
