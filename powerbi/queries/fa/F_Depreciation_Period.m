let
  Source = Csv.Document(File.Contents("data/fa_deprn_period_*.csv"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
  Promote = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
  Types = Table.TransformColumnTypes(Promote,{
    {"ASSET_ID", Int64.Type}, {"BOOK_TYPE_CODE", type text}, {"PERIOD_COUNTER", Int64.Type},
    {"PERIOD_NAME", type text}, {"DEPRN_AMOUNT", type number}, {"DEPRN_BONUS", type number},
    {"DEPRN_CATCHUP", type number}, {"DEPRN_YTD", type number}, {"DEPRN_ITD", type number}})
in  Types
