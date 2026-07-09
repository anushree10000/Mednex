-- ============================================================
-- inventory_requests table for Pharmacist → Admin requests
-- Run this in Supabase SQL Editor
-- ============================================================

CREATE TABLE IF NOT EXISTS inventory_requests (
    id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    pharmacist_id TEXT NOT NULL,
    item_name   TEXT NOT NULL,
    quantity    INTEGER NOT NULL DEFAULT 1,
    unit        TEXT NOT NULL DEFAULT 'Packs',
    priority    TEXT NOT NULL DEFAULT 'Normal',
    notes       TEXT DEFAULT '',
    status      TEXT NOT NULL DEFAULT 'Pending',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Allow authenticated users to read/write
ALTER TABLE inventory_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read"
    ON inventory_requests FOR SELECT
    TO authenticated USING (true);

CREATE POLICY "Allow authenticated insert"
    ON inventory_requests FOR INSERT
    TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated update"
    ON inventory_requests FOR UPDATE
    TO authenticated USING (true);

CREATE POLICY "Allow authenticated delete"
    ON inventory_requests FOR DELETE
    TO authenticated USING (true);
