-- External table for staging CSV data from BI Publisher
CREATE TABLE FA_BALANCES_EXT (
  ASSET_ID                  NUMBER,
  BOOK_TYPE_CODE            VARCHAR2(30),
  PERIOD_COUNTER            NUMBER,
  PERIOD_NAME               VARCHAR2(30),
  COST_BEG                  NUMBER,
  ADDITIONS                 NUMBER,
  ADJUSTMENTS               NUMBER,
  TRANSFERS_NET             NUMBER,
  RETIREMENTS_COST          NUMBER,
  DEPRN_PERIOD              NUMBER,
  DEPRN_YTD                 NUMBER,
  DEPRN_ITD                 NUMBER,
  NBV_END                   NUMBER,
  UNITS                     NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DATA_DIR
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('fa_balances_*.csv')
);
