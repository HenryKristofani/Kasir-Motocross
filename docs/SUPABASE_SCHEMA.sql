-- SQL Script untuk Supabase
-- Jalankan ini di SQL Editor Supabase dashboard sesuai urutan

-- 1. Create ticket_categories table
CREATE TABLE IF NOT EXISTS ticket_categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  day_type TEXT NOT NULL DEFAULT 'day1' CHECK (day_type IN ('day1', 'day2', 'bundling')),
  price DECIMAL(10, 2) NOT NULL,
  quota INTEGER,
  is_synced BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  local_number TEXT NOT NULL,
  device_id TEXT NOT NULL,
  pic_name TEXT,
  total DECIMAL(10, 2) NOT NULL,
  payment_method TEXT NOT NULL,
  is_voided BOOLEAN DEFAULT false,
  void_reason TEXT,
  voided_at TIMESTAMP WITH TIME ZONE,
  is_synced BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- 3. Create transaction_items table
CREATE TABLE IF NOT EXISTS transaction_items (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  category_id TEXT NOT NULL REFERENCES ticket_categories(id),
  qty INTEGER NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  price_option TEXT NOT NULL DEFAULT 'full' CHECK (price_option IN ('full', 'half', 'free', 'manual')),
  is_synced BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create shift_reconciliations table
CREATE TABLE IF NOT EXISTS shift_reconciliations (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL,
  total_sistem_tunai DECIMAL(10, 2) NOT NULL,
  total_fisik_tunai DECIMAL(10, 2) NOT NULL,
  selisih DECIMAL(10, 2) NOT NULL,
  catatan TEXT,
  is_synced BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- 5. Optional: Create events table (untuk audit trail di masa depan)
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pic_persons (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pic_persons_name
  ON pic_persons(name);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'pic_persons'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.pic_persons;
  END IF;
END
$$;

-- Migration untuk database Supabase yang sudah memiliki ticket_categories.
ALTER TABLE ticket_categories
  ADD COLUMN IF NOT EXISTS day_type TEXT NOT NULL DEFAULT 'day1';

ALTER TABLE ticket_categories
  DROP CONSTRAINT IF EXISTS ticket_categories_day_type_check;

ALTER TABLE ticket_categories
  ADD CONSTRAINT ticket_categories_day_type_check
  CHECK (day_type IN ('day1', 'day2', 'bundling'));

ALTER TABLE ticket_categories
  ALTER COLUMN quota DROP NOT NULL;

ALTER TABLE transaction_items
  ADD COLUMN IF NOT EXISTS price_option TEXT NOT NULL DEFAULT 'full';

ALTER TABLE transaction_items
  DROP CONSTRAINT IF EXISTS transaction_items_price_option_check;

ALTER TABLE transaction_items
  ADD CONSTRAINT transaction_items_price_option_check
  CHECK (price_option IN ('full', 'half', 'free', 'manual'));

ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS pic_name TEXT;

-- Default invitation paddock tickets.
INSERT INTO ticket_categories (id, name, day_type, price, quota)
VALUES
  ('paddock-undangan-day1', 'Paddock Undangan', 'day1', 0, 300),
  ('paddock-undangan-day2', 'Paddock Undangan', 'day2', 0, 300)
ON CONFLICT (id) DO NOTHING;

-- Create indexes untuk performa query
CREATE INDEX IF NOT EXISTS idx_transactions_device_id ON transactions(device_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_transactions_is_synced ON transactions(is_synced);

CREATE INDEX IF NOT EXISTS idx_transaction_items_transaction_id ON transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_items_category_id ON transaction_items(category_id);
CREATE INDEX IF NOT EXISTS idx_transaction_items_is_synced ON transaction_items(is_synced);

CREATE INDEX IF NOT EXISTS idx_ticket_categories_is_synced ON ticket_categories(is_synced);
CREATE INDEX IF NOT EXISTS idx_ticket_categories_name_day_type ON ticket_categories(name, day_type);

CREATE INDEX IF NOT EXISTS idx_shift_reconciliations_device_id ON shift_reconciliations(device_id);
CREATE INDEX IF NOT EXISTS idx_shift_reconciliations_created_at ON shift_reconciliations(created_at);
CREATE INDEX IF NOT EXISTS idx_shift_reconciliations_is_synced ON shift_reconciliations(is_synced);

-- Enable Supabase Realtime for data used by the Flutter streams.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'ticket_categories'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.ticket_categories;
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'transactions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'transaction_items'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.transaction_items;
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'shift_reconciliations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.shift_reconciliations;
  END IF;
END
$$;

-- Atomic online checkout. This is the only safe stock validation path for
-- multiple laptops using the same Supabase project.
DROP FUNCTION IF EXISTS public.create_ticket_sale(TEXT, TEXT, TEXT, INTEGER, TEXT, JSONB);

CREATE OR REPLACE FUNCTION public.create_ticket_sale(
  p_transaction_id TEXT,
  p_local_number TEXT,
  p_device_id TEXT,
  p_pic_name TEXT,
  p_total INTEGER,
  p_payment_method TEXT,
  p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  item JSONB;
  category_row RECORD;
  day1_row RECORD;
  day2_row RECORD;
  sold_qty INTEGER;
  requested_qty INTEGER;
  effective_remaining INTEGER;
  day2_sold_qty INTEGER;
  item_subtotal INTEGER;
  item_price_option TEXT;
BEGIN
  IF jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'CART_EMPTY' USING ERRCODE = 'P0001';
  END IF;

  -- Lock every selected category before calculating stock.
  FOR item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    SELECT * INTO category_row
    FROM ticket_categories
    WHERE id = item->>'category_id'
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'CATEGORY_NOT_FOUND:%', item->>'category_id' USING ERRCODE = 'P0001';
    END IF;

    requested_qty := (item->>'qty')::INTEGER;
    IF requested_qty IS NULL OR requested_qty <= 0 THEN
      RAISE EXCEPTION 'INVALID_QTY:%', category_row.name USING ERRCODE = 'P0001';
    END IF;

    IF category_row.day_type = 'bundling' THEN
      SELECT * INTO day1_row
      FROM ticket_categories
      WHERE name = category_row.name AND day_type = 'day1'
      FOR UPDATE;

      SELECT * INTO day2_row
      FROM ticket_categories
      WHERE name = category_row.name AND day_type = 'day2'
      FOR UPDATE;

      IF day1_row.id IS NULL OR day2_row.id IS NULL THEN
        RAISE EXCEPTION 'BUNDLING_PAIR_MISSING:%', category_row.name USING ERRCODE = 'P0001';
      END IF;

      SELECT COALESCE(SUM(ti.qty) FILTER (WHERE ti.category_id = day1_row.id), 0)
        + COALESCE(SUM(ti.qty) FILTER (WHERE ti.category_id = category_row.id), 0)
        INTO sold_qty
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.is_voided = false
        AND ti.category_id IN (day1_row.id, category_row.id);

      SELECT COALESCE(SUM(ti.qty) FILTER (WHERE ti.category_id = day2_row.id), 0)
        + COALESCE(SUM(ti.qty) FILTER (WHERE ti.category_id = category_row.id), 0)
        INTO day2_sold_qty
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.is_voided = false
        AND ti.category_id IN (day2_row.id, category_row.id);

      effective_remaining := LEAST(day1_row.quota - sold_qty, day2_row.quota - day2_sold_qty);
    ELSE
      SELECT COALESCE(SUM(ti.qty), 0) INTO sold_qty
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.is_voided = false
        AND ti.category_id = category_row.id;

      effective_remaining := COALESCE(category_row.quota, 2147483647) - sold_qty;
    END IF;

    IF requested_qty > effective_remaining THEN
      RAISE EXCEPTION 'INSUFFICIENT_QUOTA:%:%:%', category_row.name, effective_remaining, requested_qty USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  INSERT INTO transactions (id, local_number, device_id, pic_name, total, payment_method, is_voided, created_at)
  VALUES (p_transaction_id, p_local_number, p_device_id, p_pic_name, p_total, p_payment_method, false, NOW());

  FOR item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    SELECT price INTO category_row
    FROM ticket_categories
    WHERE id = item->>'category_id';

    item_price_option := COALESCE(item->>'price_option', 'full');
    IF item_price_option NOT IN ('full', 'half', 'free', 'manual') THEN
      RAISE EXCEPTION 'INVALID_PRICE_OPTION:%', item_price_option USING ERRCODE = 'P0001';
    END IF;

    IF item_price_option = 'manual'
       AND ((item->>'subtotal') IS NULL OR (item->>'subtotal')::INTEGER < 0) THEN
      RAISE EXCEPTION 'INVALID_MANUAL_PRICE' USING ERRCODE = 'P0001';
    END IF;

    item_subtotal := CASE item_price_option
      WHEN 'half' THEN (category_row.price::INTEGER * (item->>'qty')::INTEGER) / 2
      WHEN 'free' THEN 0
      WHEN 'manual' THEN COALESCE((item->>'subtotal')::INTEGER, 0)
      ELSE category_row.price::INTEGER * (item->>'qty')::INTEGER
    END;

    INSERT INTO transaction_items (id, transaction_id, category_id, qty, subtotal, price_option)
    VALUES (
      COALESCE(item->>'id', gen_random_uuid()::TEXT),
      p_transaction_id,
      item->>'category_id',
      (item->>'qty')::INTEGER,
      item_subtotal,
      COALESCE(item->>'price_option', 'full')
    );
  END LOOP;

  RETURN jsonb_build_object('transaction_id', p_transaction_id, 'status', 'created');
END;
$$;

-- CATATAN PENTING:
-- 1. Jalankan semua CREATE TABLE dulu (1-4), jangan langsung jalankan semuanya sekaligus
-- 2. Setelah table terbuat, baru jalankan CREATE INDEX
-- 3. Verifikasi di Table Editor Supabase bahwa semua table sudah ada
-- 4. Dalam app, auto-sync akan mulai upload record dengan is_synced=false
-- 5. Table ini tidak memiliki RLS policy (Row Level Security) aktif - sesuaikan dengan kebutuhan keamanan Anda
