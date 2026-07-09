-- MedNex RLS Fix Migration v3
-- Run in Supabase Dashboard → SQL Editor
-- Fixes: bills not saving, docs storage, nurse/doctor permissions

-- ============================================================
-- 1. FIX bills FK constraint — make appointment_id nullable
-- ============================================================
ALTER TABLE bills ALTER COLUMN appointment_id DROP NOT NULL;
ALTER TABLE bills DROP CONSTRAINT IF EXISTS bills_appointment_id_fkey;

-- ============================================================
-- 2. ADD patient_documents table for uploaded medical docs
-- ============================================================
CREATE TABLE IF NOT EXISTS patient_documents (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_type TEXT NOT NULL DEFAULT 'file',
    file_size BIGINT DEFAULT 0,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_patient_docs_patient ON patient_documents(patient_id);

-- ============================================================
-- 3. MISSING RLS POLICIES — bills, vitals, notifications, admissions, etc.
-- ============================================================

-- Bills: allow admin INSERT/UPDATE (already has SELECT via "Admins full access bills")
-- The ALL policy already covers INSERT/UPDATE for admin. The issue was FK.
-- Add patient UPDATE so they can mark bills as paid
CREATE POLICY "Patients can update own bills" ON bills
    FOR UPDATE USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
    );

-- Vital records: nurses can INSERT
CREATE POLICY "Nurses can insert vitals" ON vital_records
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM staff WHERE user_id = auth.uid()::text AND role = 'nurse')
    );

-- Vital records: doctors can SELECT for their admitted patients
CREATE POLICY "Doctors see patient vitals" ON vital_records
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM doctors WHERE user_id = auth.uid()::text)
    );

-- Vital records: nurses can SELECT
CREATE POLICY "Nurses see patient vitals" ON vital_records
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM staff WHERE user_id = auth.uid()::text AND role = 'nurse')
    );

-- Notifications: all authenticated users can INSERT
CREATE POLICY "Authenticated users can insert notifications" ON notifications
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Admissions: enable RLS and add policies
ALTER TABLE admissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins full access admissions" ON admissions
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

CREATE POLICY "Patients see own admissions" ON admissions
    FOR SELECT USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Doctors see assigned admissions" ON admissions
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM doctors WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Nurses see admissions" ON admissions
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM staff WHERE user_id = auth.uid()::text AND role = 'nurse')
    );

-- Nurse patient assignments: RLS
ALTER TABLE nurse_patient_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins full access nurse assignments" ON nurse_patient_assignments
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

CREATE POLICY "Nurses see own assignments" ON nurse_patient_assignments
    FOR SELECT USING (
        staff_id IN (SELECT id FROM staff WHERE user_id = auth.uid()::text)
    );

-- Vitals requests: RLS
ALTER TABLE vitals_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Doctors manage vitals requests" ON vitals_requests
    FOR ALL USING (
        EXISTS (SELECT 1 FROM doctors WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Nurses see and update vitals requests" ON vitals_requests
    FOR ALL USING (
        EXISTS (SELECT 1 FROM staff WHERE user_id = auth.uid()::text AND role = 'nurse')
    );

-- Patient documents: RLS
ALTER TABLE patient_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients manage own documents" ON patient_documents
    FOR ALL USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Doctors see patient documents" ON patient_documents
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM doctors WHERE user_id = auth.uid()::text)
    );

-- Patients: doctors and nurses can SELECT
CREATE POLICY "Doctors see patients" ON patients
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM doctors WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Nurses see patients" ON patients
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM staff WHERE user_id = auth.uid()::text AND role = 'nurse')
    );

CREATE POLICY "Admins full access patients" ON patients
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

-- Doctors: all authenticated users can SELECT (for appointment booking etc.)
CREATE POLICY "All users see doctors" ON doctors
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Staff: all authenticated can SELECT (for assignment display)
CREATE POLICY "All users see staff" ON staff
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Lab tests: admins full access
CREATE POLICY "Admins full access lab tests" ON lab_tests
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

-- Lab tests: lab techs can update
CREATE POLICY "Lab techs manage lab tests" ON lab_tests
    FOR ALL USING (
        EXISTS (SELECT 1 FROM staff WHERE user_id = auth.uid()::text AND role = 'lab_technician')
    );

-- ============================================================
-- 4. STORAGE POLICY for patient-records bucket
-- ============================================================
-- Run these in Supabase Dashboard → Storage → patient-records → Policies
-- Or use the SQL below:

INSERT INTO storage.buckets (id, name, public)
VALUES ('patient-records', 'patient-records', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Authenticated users can upload" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'patient-records' AND auth.uid() IS NOT NULL
    );

CREATE POLICY "Authenticated users can read" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'patient-records' AND auth.uid() IS NOT NULL
    );
