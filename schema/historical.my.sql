CREATE TABLE transactions (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  hash            BINARY(32),
  type            ENUM(‘Payment’, ‘OfferCreate’, ‘OfferCancel’, ‘AccountSet’, ‘SetRegularKey’, ‘TrustSet’),
  from_account        BIGINT UNSIGNED,
  from_sequence        BIGINT UNSIGNED,
  ledger_sequence        BIGINT UNSIGNED,
  // XXX Should this be a string containing the whole engine_result?
  status            CHARACTER(1),
  raw                BINARY VARYING(1GB),
  meta            BINARY VARYING(1GB)

  CONSTRAINT fk_from_account
    FOREIGN KEY (from_account)
    REFERENCES accounts(id)
);

CREATE INDEX transaction_ledger_index
          ON transactions(ledger_sequence);

; ------------------------------------------------------------------

CREATE TABLE ledger_transactions (
  transaction_id        BIGINT UNSIGNED,
  ledger_id            BIGINT UNSIGNED,
  transaction_sequence    INTEGER UNSIGNED,

  CONSTRAINT fk_transaction_id
    FOREIGN KEY (transaction_id)
    REFERENCES transactions(id)
  CONSTRAINT fk_ledger_id
    FOREIGN KEY (ledger_id)
    REFERENCES ledgers(id)
);

CREATE INDEX ledger_transaction_id_index
          ON ledger_transactions(transaction_id);

CREATE UNIQUE INDEX ledger_transaction_index
              ON ledger_transactions(ledger_id, transaction_sequence);

; ------------------------------------------------------------------

CREATE TABLE accounts (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  address            BINARY(20)
);

CREATE TABLE account_transactions (
  transaction_id        BIGINT UNSIGNED,
  account_id        BIGINT UNSIGNED,
  ledger_sequence        BIGINT UNSIGNED,
  transaction_sequence    INTEGER UNSIGNED,

  CONSTRAINT fk_transaction_id
    FOREIGN KEY (transaction_id)
    REFERENCES transactions(id)
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

; ------------------------------------------------------------------

CREATE TABLE ledgers (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  hash            BINARY(32),
  sequence            BIGINT UNSIGNED,
  prev_hash            BINARY(32),
  total_coins        BIGINT UNSIGNED,
  closing_time        BIGINT UNSIGNED,
  prev_closing_time    BIGINT UNSIGNED,
  close_time_resolution    BIGINT UNSIGNED,
  close_flags        BIGINT UNSIGNED,
  account_set_hash    BINARY(32),
  transaction_set_hash    BINARY(32)
);

CREATE INDEX ledger_sequence_index
          ON ledgers(ledger_sequence);

CREATE INDEX ledger_time_index
          ON ledgers(closing_time);