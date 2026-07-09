-- ============================================================
-- MedNex – Recreate doctor_blocks table (drop + create)
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- Force-drop old table (may have wrong columns)
DROP TABLE IF EXISTS doctor_blocks;

-- Recreate with correct schema
CREATE TABLE doctor_blocks (
    id text PRIMARY KEY,
    doctor_id text NOT NULL,
    block_date text NOT NULL,
    slot text NOT NULL,
    created_at timestamptz DEFAULT now(),
    UNIQUE(doctor_id, block_date, slot)
);

-- Disable RLS
ALTER TABLE doctor_blocks DISABLE ROW LEVEL SECURITY;

-- Grant access
GRANT ALL ON doctor_blocks TO anon;
GRANT ALL ON doctor_blocks TO authenticated;

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE doctor_blocks;

SELECT '✅ doctor_blocks table recreated with correct schema' AS result;
