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

-- CATATAN PENTING:
-- 1. Jalankan semua CREATE TABLE dulu (1-4), jangan langsung jalankan semuanya sekaligus
-- 2. Setelah table terbuat, baru jalankan CREATE INDEX
-- 3. Verifikasi di Table Editor Supabase bahwa semua table sudah ada
-- 4. Dalam app, auto-sync akan mulai upload record dengan is_synced=false
-- 5. Table ini tidak memiliki RLS policy (Row Level Security) aktif - sesuaikan dengan kebutuhan keamanan Anda
