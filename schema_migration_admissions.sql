-- ============================================================
-- MedNex Schema Migration: Add Admissions Table
-- Run this in Supabase Dashboard → SQL Editor
-- (Only needed if you already deployed the base schema)
-- ============================================================

-- 1. Add admissions table
CREATE TABLE IF NOT EXISTS admissions (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    patient_id      TEXT NOT NULL,
    doctor_id       TEXT,
    bed_id          TEXT,
    department_id   TEXT,
    admission_date  TIMESTAMPTZ NOT NULL DEFAULT now(),
    discharge_date  TIMESTAMPTZ,
    status          TEXT NOT NULL DEFAULT 'admitted',
    diagnosis       TEXT,
    daily_room_rate DOUBLE PRECISION NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_admissions_patient ON admissions(patient_id);
CREATE INDEX IF NOT EXISTS idx_admissions_status ON admissions(status);

-- 2. Enable RLS and add open policy
ALTER TABLE admissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for anon" ON admissions;
CREATE POLICY "Allow all for anon" ON admissions FOR ALL USING (true) WITH CHECK (true);

-- 3. Add profile_image_url to patients (if missing)
ALTER TABLE patients ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- 4. Enable Realtime for admissions
ALTER PUBLICATION supabase_realtime ADD TABLE admissions;

SELECT 'Migration complete!' AS status;
