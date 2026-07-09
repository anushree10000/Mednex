-- ============================================================
-- MedNex – Schema Migration v2
-- Run this in Supabase Dashboard → SQL Editor
-- Adds: multi-doctor admissions, nurse assignments, vitals requests
-- ============================================================

-- Admissions: add new columns
ALTER TABLE admissions ADD COLUMN IF NOT EXISTS ward_number TEXT;
ALTER TABLE admissions ADD COLUMN IF NOT EXISTS bed_number TEXT;
ALTER TABLE admissions ADD COLUMN IF NOT EXISTS doctor_ids JSONB DEFAULT '[]';
ALTER TABLE admissions ADD COLUMN IF NOT EXISTS nurse_id TEXT;
ALTER TABLE admissions ADD COLUMN IF NOT EXISTS patient_name TEXT;

-- Vital records: track who requested the vitals
ALTER TABLE vital_records ADD COLUMN IF NOT EXISTS requested_by TEXT;

-- Vitals requests table (doctor → nurse)
CREATE TABLE IF NOT EXISTS vitals_requests (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    doctor_id       TEXT NOT NULL,
    patient_id      TEXT NOT NULL,
    nurse_id        TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_vr_nurse ON vitals_requests(nurse_id);
CREATE INDEX IF NOT EXISTS idx_vr_doctor ON vitals_requests(doctor_id);
CREATE INDEX IF NOT EXISTS idx_vr_patient ON vitals_requests(patient_id);

-- RLS for vitals_requests
ALTER TABLE vitals_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for anon" ON vitals_requests;
CREATE POLICY "Allow all for anon" ON vitals_requests FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- DONE
-- ============================================================
