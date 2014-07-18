-- ; ------------------------------------------------------------------
/*
    TODO:
        Consider timestamp for transactions
    DONE:
        Ascertain closest sql family - mysql
        Add index to transaction hash
        Add unix timestamp field to ledgers
        compact fields - s/BIGINT/INT/ where field maps to STI_UINT32 etc
        Add an enum for the TER
        transactions.type ENUM must support full history - seems missing some
        Make mysql importable
        Convert to postgresql
            -- http://en.wikibooks.org/wiki/Converting_MySQL_to_PostgreSQL#SQL
*/

CREATE TABLE accounts (
  id      BIGSERIAL primary key,
  -- This probably makes more sense than using varchar, but does complicate
  -- interaction at the console, can write some pl/sql funcs.
  address BYTEA -- (20)
);

-- Ledger header fields from ripple-lib-java
-- UInt32  sequence;        // Ledger Sequence (0 for genesis ledger)
-- UInt64  totalXRP;        //
-- Hash256 previousLedger;  // The hash of the previous ledger (0 for genesis ledger)
-- Hash256 transactionHash; // The hash of the transaction tree's root node.
-- Hash256 stateHash;       // The hash of the state tree's root node.
-- UInt32  parentCloseTime; // The time the previous ledger closed
-- UInt32  closeTime;       // UTC minute ledger closed encoded as seconds since 1/1/2000 (or 0 for genesis ledger)
-- UInt8   closeResolution; // The resolution (in seconds) of the close time
-- UInt8   closeFlags;      // Flags
CREATE TABLE ledgers (
  id                    BIGSERIAL primary key,
  sequence              BIGINT,
  total_coins           NUMERIC,

  -- Ripple timestamps are 32 bit unsigned ints
  closing_time          BIGINT,
  -- closing_time_unix     TIMESTAMP,
  prev_closing_time     BIGINT,

  close_time_resolution SMALLINT,
  close_flags           SMALLINT,

  -- changed these fields to match the fields used in the json dumps
  hash                  BYTEA, -- 32
  parent_hash           BYTEA, -- 32 
  account_hash          BYTEA, -- 32 
  transaction_hash      BYTEA  -- 32
 );

CREATE INDEX ledger_sequence_index
          ON ledgers(sequence);

CREATE INDEX ledger_time_index
          ON ledgers(closing_time);

CREATE TYPE transction_type AS ENUM('Payment',
                        'Claim',
                        'WalletAdd',
                        'AccountSet',
                        'PasswordFund',
                        'SetRegularKey',
                        'NickNameSet',
                        'OfferCreate',
                        'OfferCancel',
                        'Contract',
                        'RemoveContract',
                        'TrustSet',
                        'EnableFeature',
                        'SetFee');

CREATE TYPE transction_engine_result AS ENUM(
    'tesSUCCESS', -- The transaction was applied.,
    'tecCLAIM', -- Fee claimed. Sequence used. No action.,
    'tecPATH_PARTIAL', -- Path could not send full amount.,
    'tecUNFUNDED_ADD', -- Insufficient XRP balance for WalletAdd.,
    'tecUNFUNDED_OFFER', -- Insufficient balance to fund created offer.,
    'tecUNFUNDED_PAYMENT', -- Insufficient XRP balance to send.,
    'tecFAILED_PROCESSING', -- Failed to correctly process transaction.,
    'tecDIR_FULL', -- Can not add entry to full directory.,
    'tecINSUF_RESERVE_LINE', -- Insufficient reserve to add trust line.,
    'tecINSUF_RESERVE_OFFER', -- Insufficient reserve to create offer.,
    'tecNO_DST', -- Destination does not exist. Send XRP to create it.,
    'tecNO_DST_INSUF_XRP', -- Destination does not exist. Too little XRP sent to create it.,
    'tecNO_LINE_INSUF_RESERVE', -- No such line. Too little reserve to create it.,
    'tecNO_LINE_REDUNDANT', -- Can't set non-existant line to default.,
    'tecPATH_DRY', -- Path could not send partial amount.,
    'tecUNFUNDED', -- One of _ADD, _OFFER, or _SEND. Deprecated.,
    'tecMASTER_DISABLED', 
    'tecNO_REGULAR_KEY', 
    'tecOWNERS');

CREATE TABLE transactions (
  id               BIGSERIAL primary key,
  hash             BYTEA,

  type             transction_type,

  from_sequence    BIGINT,
  ledger_sequence  BIGINT,

  -- transaction engine result class, stores te(c) or te(s)
  status           CHARACTER(1),

  -- note that actually importing all this would require parsing the metadata
  ter              transction_engine_result,
  raw              BYTEA,
  meta             BYTEA,

  from_account     BIGINT,
  CONSTRAINT fk_from_account
    FOREIGN KEY (from_account)
    REFERENCES accounts(id)
);

CREATE INDEX transaction_ledger_index
          ON transactions(ledger_sequence);

-- querying transactions by hash is likely a common operation
CREATE INDEX transaction_hash
          ON transactions(hash);

-- ; ------------------------------------------------------------------

CREATE TABLE ledger_transactions (
  transaction_id       BIGINT,
  ledger_id            BIGINT,
  transaction_sequence BIGINT,

  CONSTRAINT fk_transaction_id
    FOREIGN KEY (transaction_id)
    REFERENCES transactions(id),

  CONSTRAINT fk_ledger_id
    FOREIGN KEY (ledger_id)
    REFERENCES ledgers(id)
);

CREATE INDEX ledger_transaction_id_index
          ON ledger_transactions(transaction_id);

CREATE UNIQUE INDEX ledger_transaction_index
              ON ledger_transactions(ledger_id, transaction_sequence);

-- ; ------------------------------------------------------------------

CREATE TABLE account_transactions (
  transaction_id       BIGINT,
  account_id           BIGINT,
  ledger_sequence      BIGINT,
  transaction_sequence BIGINT,

  CONSTRAINT fk_transaction_id
    FOREIGN KEY (transaction_id)
    REFERENCES transactions(id),

  CONSTRAINT fk_account_id
    FOREIGN KEY (account_id)
    REFERENCES accounts(id)
);

CREATE INDEX account_transaction_id_index
          ON account_transactions(transaction_id);

CREATE INDEX account_transaction_index
          ON account_transactions(account_id, ledger_sequence, transaction_sequence, transaction_id);

CREATE INDEX account_ledger_index
          ON account_transactions(ledger_sequence, account_id, transaction_id);

-- ; ------------------------------------------------------------------