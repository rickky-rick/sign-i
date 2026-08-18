/*
# Create webmail database schema

## Overview
This migration creates the core database tables for the webmail application.
The app currently has a login form that only validates locally; this schema
provides the backend storage so the app can store email accounts and messages.

## New Tables

### accounts
Stores webmail user accounts (email address + password hash, display name).
- id (uuid, primary key)
- email (text, unique, not null) — the user's login email
- password_hash (text, not null) — hashed password (never store plaintext)
- display_name (text) — friendly name shown in the mailbox
- created_at (timestamptz, defaults to now)

### messages
Stores email messages belonging to an account.
- id (uuid, primary key)
- account_id (uuid, foreign key → accounts.id, cascade delete)
- from_address (text, not null) — sender email
- to_address (text, not null) — recipient email
- subject (text) — email subject line
- body (text) — email body content
- is_read (boolean, default false) — whether the message has been read
- received_at (timestamptz, defaults to now) — when the message arrived
- created_at (timestamptz, defaults to now)

## Indexes
- accounts.email (unique index for fast login lookups)
- messages.account_id (for listing a user's mailbox)

## Security
- Row Level Security enabled on both tables.
- Policies allow anon + authenticated CRUD on both tables (single-tenant /
  shared-data model — no Supabase Auth sign-in flow was requested).

## Important Notes
1. This is a single-tenant schema: all data is shared and accessible via
   the anon key. If you later add user sign-in, the policies should be
   tightened to scope each account's data to its owner using auth.uid().
2. Passwords must always be hashed before storing in password_hash —
   never store plaintext passwords.
3. The messages table references accounts via account_id; deleting an
   account cascades and removes its messages.
*/

CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  display_name text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  from_address text NOT NULL,
  to_address text NOT NULL,
  subject text,
  body text,
  is_read boolean NOT NULL DEFAULT false,
  received_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_account_id ON messages(account_id);

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- accounts policies (single-tenant: anon + authenticated)
DROP POLICY IF EXISTS "anon_select_accounts" ON accounts;
CREATE POLICY "anon_select_accounts" ON accounts FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_accounts" ON accounts;
CREATE POLICY "anon_insert_accounts" ON accounts FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_accounts" ON accounts;
CREATE POLICY "anon_update_accounts" ON accounts FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_accounts" ON accounts;
CREATE POLICY "anon_delete_accounts" ON accounts FOR DELETE
  TO anon, authenticated USING (true);

-- messages policies (single-tenant: anon + authenticated)
DROP POLICY IF EXISTS "anon_select_messages" ON messages;
CREATE POLICY "anon_select_messages" ON messages FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_messages" ON messages;
CREATE POLICY "anon_insert_messages" ON messages FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_messages" ON messages;
CREATE POLICY "anon_update_messages" ON messages FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_messages" ON messages;
CREATE POLICY "anon_delete_messages" ON messages FOR DELETE
  TO anon, authenticated USING (true);
