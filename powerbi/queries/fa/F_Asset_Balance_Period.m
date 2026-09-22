let
  Source = Csv.Document(File.Contents("data/fa_balances_*.csv"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
  Promote = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
  Types = Table.TransformColumnTypes(Promote,{
    {"ASSET_ID", Int64.Type}, {"BOOK_TYPE_CODE", type text}, {"PERIOD_COUNTER", Int64.Type},
    {"PERIOD_NAME", type text}, {"COST_BEG", type number}, {"ADDITIONS", type number},
    {"ADJUSTMENTS", type number}, {"TRANSFERS_NET", type number}, {"RETIREMENTS_COST", type number},
    {"DEPRN_PERIOD", type number}, {"DEPRN_YTD", type number}, {"DEPRN_ITD", type number},
    {"NBV_END", type number}, {"UNITS", type number}})
in  Types
