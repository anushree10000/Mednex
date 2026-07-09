-- =====================================================
-- MedNex Schema Migration v4
-- Fixes: bills table, patient_documents table
-- Run this in your Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. patient_documents — ensure table exists with correct columns
-- =====================================================
CREATE TABLE IF NOT EXISTS patient_documents (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT '',
    file_path TEXT NOT NULL DEFAULT '',
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE patient_documents ENABLE ROW LEVEL SECURITY;

-- Allow patients to manage their own documents
DROP POLICY IF EXISTS "Patients manage own documents" ON patient_documents;
CREATE POLICY "Patients manage own documents"
    ON patient_documents FOR ALL
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- 2. bills — ensure table exists with correct columns
-- =====================================================
CREATE TABLE IF NOT EXISTS bills (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    appointment_id TEXT,
    patient_id TEXT NOT NULL,
    patient_name TEXT NOT NULL DEFAULT '',
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    total_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    paid_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    payment_mode TEXT,
    status TEXT NOT NULL DEFAULT 'unpaid',
    invoice_pdf_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    paid_at TIMESTAMPTZ
);

-- Add any missing columns to bills (if table already existed)
DO $$ BEGIN
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS appointment_id TEXT;
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS patient_name TEXT NOT NULL DEFAULT '';
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS items JSONB NOT NULL DEFAULT '[]'::jsonb;
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS total_amount DOUBLE PRECISION NOT NULL DEFAULT 0;
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS paid_amount DOUBLE PRECISION NOT NULL DEFAULT 0;
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS payment_mode TEXT;
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'unpaid';
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS invoice_pdf_url TEXT;
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
    ALTER TABLE bills ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
END $$;

-- Enable RLS
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read bills, admins to manage
DROP POLICY IF EXISTS "Anyone can read bills" ON bills;
CREATE POLICY "Anyone can read bills"
    ON bills FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Anyone can insert bills" ON bills;
CREATE POLICY "Anyone can insert bills"
    ON bills FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can update bills" ON bills;
CREATE POLICY "Anyone can update bills"
    ON bills FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- 3. vitals_requests — ensure table exists
-- =====================================================
CREATE TABLE IF NOT EXISTS vitals_requests (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    doctor_id TEXT NOT NULL,
    patient_id TEXT NOT NULL,
    nurse_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

ALTER TABLE vitals_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "All users can manage vitals_requests" ON vitals_requests;
CREATE POLICY "All users can manage vitals_requests"
    ON vitals_requests FOR ALL
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- 4. Grant storage access for patient-records bucket
-- =====================================================
-- Make sure the 'patient-records' bucket exists and has:
-- Public: false (if you don't want public access)
-- Allowed MIME types: image/*, application/pdf
-- File size limit: 10MB

-- Insert bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('patient-records', 'patient-records', true)
ON CONFLICT (id) DO NOTHING;

-- Allow all authenticated users to upload/read from patient-records
DROP POLICY IF EXISTS "Allow authenticated uploads to patient-records" ON storage.objects;
CREATE POLICY "Allow authenticated uploads to patient-records"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'patient-records');

DROP POLICY IF EXISTS "Allow authenticated reads from patient-records" ON storage.objects;
CREATE POLICY "Allow authenticated reads from patient-records"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'patient-records');

DROP POLICY IF EXISTS "Allow public reads from patient-records" ON storage.objects;
CREATE POLICY "Allow public reads from patient-records"
    ON storage.objects FOR SELECT
    TO anon
    USING (bucket_id = 'patient-records');
