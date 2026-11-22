-- ============================================================
-- MedNex – full database setup for a NEW Supabase project
--
-- Builds the complete schema the app expects, in the order the
-- team's migrations were applied, plus sample departments, beds
-- and inventory. Paste into Supabase Dashboard → SQL Editor → Run.
--
-- Security is still in development mode after this (RLS off, open
-- grants) so the app's demo-account seeder can run. Switch real
-- security on afterwards with schema_migration_v6_security_realtime.sql
-- (see SECURITY_SETUP.md).
--
-- Generated from: supabase_schema.sql, supabase_permissions.sql,
-- schema_migration_v2–v5, schema_migration_admissions.sql,
-- supabase_inventory_requests.sql, create_doctor_blocks.sql,
-- fix_appointments_schema.sql, drop_fk_constraints.sql,
-- enable_realtime.sql, supabase_seed_data.sql
-- ============================================================


-- ############################################################
-- ## supabase_schema.sql
-- ############################################################

-- ============================================================
-- MedNex – Supabase PostgreSQL Schema
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- Drop all existing tables (CASCADE removes dependent objects)
DROP TABLE IF EXISTS admissions CASCADE;
DROP TABLE IF EXISTS nurse_patient_assignments CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_sessions CASCADE;
DROP TABLE IF EXISTS time_slots CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;
DROP TABLE IF EXISTS beds CASCADE;
DROP TABLE IF EXISTS inventory_items CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS vital_records CASCADE;
DROP TABLE IF EXISTS bill_items CASCADE;
DROP TABLE IF EXISTS bills CASCADE;
DROP TABLE IF EXISTS lab_test_results CASCADE;
DROP TABLE IF EXISTS lab_tests CASCADE;
DROP TABLE IF EXISTS prescribed_medicines CASCADE;
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ————————————————————————————————————————
-- 1. USERS  (linked to Firebase Auth UIDs)
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS users (
    id              TEXT PRIMARY KEY,          -- Firebase UID
    email           TEXT NOT NULL UNIQUE,
    role            TEXT NOT NULL DEFAULT 'patient',
    display_name    TEXT NOT NULL DEFAULT '',
    profile_image_url TEXT,
    phone_number    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login      TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- ————————————————————————————————————————
-- 2. PATIENTS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS patients (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    personal_info   JSONB NOT NULL DEFAULT '{}',
    emergency_contacts JSONB NOT NULL DEFAULT '[]',
    medical_info    JSONB NOT NULL DEFAULT '{}',
    profile_image_url TEXT
);
CREATE INDEX IF NOT EXISTS idx_patients_user ON patients(user_id);

-- ————————————————————————————————————————
-- 3. DEPARTMENTS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS departments (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    name            TEXT NOT NULL,
    head_doctor_id  TEXT,
    head_doctor_name TEXT,
    staff_count     INT NOT NULL DEFAULT 0,
    location        TEXT NOT NULL DEFAULT '',
    description     TEXT NOT NULL DEFAULT '',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ————————————————————————————————————————
-- 4. DOCTORS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS doctors (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    specialty       TEXT NOT NULL DEFAULT 'General Medicine',
    experience      INT NOT NULL DEFAULT 0,
    license_number  TEXT NOT NULL DEFAULT '',
    consultation_fee DOUBLE PRECISION NOT NULL DEFAULT 500,
    department_id   TEXT REFERENCES departments(id),
    rating          DOUBLE PRECISION NOT NULL DEFAULT 4.5,
    total_ratings   INT NOT NULL DEFAULT 0,
    available_slots JSONB NOT NULL DEFAULT '[]',
    bio             TEXT NOT NULL DEFAULT '',
    education       TEXT NOT NULL DEFAULT '',
    languages       JSONB NOT NULL DEFAULT '["English"]',
    is_available    BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_doctors_user ON doctors(user_id);
CREATE INDEX IF NOT EXISTS idx_doctors_dept ON doctors(department_id);

-- ————————————————————————————————————————
-- 5. STAFF  (nurses, lab techs, pharmacists, etc.)
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS staff (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id         TEXT NOT NULL DEFAULT '',
    name            TEXT NOT NULL,
    role            TEXT NOT NULL DEFAULT 'nurse',
    department_id   TEXT NOT NULL DEFAULT '',
    department_name TEXT NOT NULL DEFAULT '',
    phone           TEXT NOT NULL DEFAULT '',
    email           TEXT NOT NULL DEFAULT '',
    shift           TEXT NOT NULL DEFAULT 'Morning',
    join_date       TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    qualifications  TEXT NOT NULL DEFAULT '',
    specialization  TEXT
);

-- ————————————————————————————————————————
-- 6. APPOINTMENTS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS appointments (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    patient_id      TEXT NOT NULL,
    patient_name    TEXT NOT NULL DEFAULT '',
    doctor_id       TEXT NOT NULL,
    doctor_name     TEXT NOT NULL DEFAULT '',
    specialty       TEXT NOT NULL DEFAULT 'General Medicine',
    date_time       TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    status          TEXT NOT NULL DEFAULT 'scheduled',
    type            TEXT NOT NULL DEFAULT 'consultation',
    notes           TEXT NOT NULL DEFAULT '',
    prescription_id TEXT,
    billing_status  TEXT NOT NULL DEFAULT 'pending',
    cancellation_reason TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    symptoms        TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_appts_patient ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appts_doctor  ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appts_date    ON appointments(date_time);

-- ————————————————————————————————————————
-- 7. PRESCRIPTIONS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS prescriptions (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    appointment_id  TEXT NOT NULL DEFAULT '',
    patient_id      TEXT NOT NULL,
    patient_name    TEXT NOT NULL DEFAULT '',
    doctor_id       TEXT NOT NULL,
    doctor_name     TEXT NOT NULL DEFAULT '',
    medicines       JSONB NOT NULL DEFAULT '[]',
    diagnosis       TEXT NOT NULL DEFAULT '',
    notes           TEXT NOT NULL DEFAULT '',
    pdf_url         TEXT,
    status          TEXT NOT NULL DEFAULT 'active',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rx_patient ON prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_rx_doctor  ON prescriptions(doctor_id);

-- ————————————————————————————————————————
-- 8. PRESCRIBED_MEDICINES  (line items)
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS prescribed_medicines (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    prescription_id TEXT NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    name            TEXT NOT NULL DEFAULT '',
    dosage          TEXT NOT NULL DEFAULT '',
    frequency       TEXT NOT NULL DEFAULT 'Once Daily',
    duration        TEXT NOT NULL DEFAULT '',
    instructions    TEXT NOT NULL DEFAULT '',
    is_taken        BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_pm_rx ON prescribed_medicines(prescription_id);

-- ————————————————————————————————————————
-- 9. LAB_TESTS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS lab_tests (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    patient_id      TEXT NOT NULL,
    patient_name    TEXT NOT NULL DEFAULT '',
    doctor_id       TEXT NOT NULL,
    doctor_name     TEXT NOT NULL DEFAULT '',
    test_name       TEXT NOT NULL,
    test_category   TEXT NOT NULL DEFAULT 'Blood Work',
    status          TEXT NOT NULL DEFAULT 'pending',
    priority        TEXT NOT NULL DEFAULT 'routine',
    results         JSONB NOT NULL DEFAULT '[]',
    notes           TEXT NOT NULL DEFAULT '',
    report_pdf_url  TEXT,
    ordered_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_lab_patient ON lab_tests(patient_id);
CREATE INDEX IF NOT EXISTS idx_lab_doctor  ON lab_tests(doctor_id);

-- ————————————————————————————————————————
-- 10. LAB_TEST_RESULTS  (individual parameters)
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS lab_test_results (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    lab_test_id     TEXT NOT NULL REFERENCES lab_tests(id) ON DELETE CASCADE,
    parameter_name  TEXT NOT NULL DEFAULT '',
    value           TEXT NOT NULL DEFAULT '',
    unit            TEXT NOT NULL DEFAULT '',
    normal_range    TEXT NOT NULL DEFAULT '',
    is_abnormal     BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_ltr_test ON lab_test_results(lab_test_id);

-- ————————————————————————————————————————
-- 11. BILLS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS bills (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    appointment_id  TEXT NOT NULL DEFAULT '',
    patient_id      TEXT NOT NULL,
    patient_name    TEXT NOT NULL DEFAULT '',
    items           JSONB NOT NULL DEFAULT '[]',
    total_amount    DOUBLE PRECISION NOT NULL DEFAULT 0,
    paid_amount     DOUBLE PRECISION NOT NULL DEFAULT 0,
    payment_mode    TEXT,
    status          TEXT NOT NULL DEFAULT 'unpaid',
    invoice_pdf_url TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    paid_at         TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_bills_patient ON bills(patient_id);

-- ————————————————————————————————————————
-- 12. BILL_ITEMS  (line items)
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS bill_items (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    bill_id         TEXT NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    description     TEXT NOT NULL DEFAULT '',
    quantity        INT NOT NULL DEFAULT 1,
    unit_price      DOUBLE PRECISION NOT NULL DEFAULT 0,
    total           DOUBLE PRECISION NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_bi_bill ON bill_items(bill_id);

-- ————————————————————————————————————————
-- 13. VITAL_RECORDS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS vital_records (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    patient_id      TEXT NOT NULL,
    recorded_by     TEXT NOT NULL DEFAULT '',
    timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
    blood_pressure_systolic   DOUBLE PRECISION,
    blood_pressure_diastolic  DOUBLE PRECISION,
    heart_rate      DOUBLE PRECISION,
    temperature     DOUBLE PRECISION,
    respiratory_rate DOUBLE PRECISION,
    oxygen_saturation DOUBLE PRECISION,
    weight          DOUBLE PRECISION,
    height          DOUBLE PRECISION,
    blood_glucose   DOUBLE PRECISION,
    notes           TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_vitals_patient ON vital_records(patient_id);

-- ————————————————————————————————————————
-- 14. NOTIFICATIONS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS notifications (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id         TEXT NOT NULL,
    type            TEXT NOT NULL DEFAULT 'general',
    title           TEXT NOT NULL DEFAULT '',
    body            TEXT NOT NULL DEFAULT '',
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    related_id      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id);

-- ————————————————————————————————————————
-- 15. INVENTORY_ITEMS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS inventory_items (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    name            TEXT NOT NULL,
    category        TEXT NOT NULL DEFAULT 'Medication',
    stock           INT NOT NULL DEFAULT 0,
    reorder_level   INT NOT NULL DEFAULT 10,
    unit_price      DOUBLE PRECISION NOT NULL DEFAULT 0,
    supplier        TEXT NOT NULL DEFAULT '',
    last_updated    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ————————————————————————————————————————
-- 16. BEDS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS beds (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    number          TEXT NOT NULL,
    ward            TEXT NOT NULL DEFAULT '',
    floor           TEXT NOT NULL DEFAULT '',
    status          TEXT NOT NULL DEFAULT 'available',
    patient_name    TEXT
);

-- ————————————————————————————————————————
-- 17. SHIFTS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS shifts (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    staff_id        TEXT NOT NULL,
    staff_name      TEXT NOT NULL DEFAULT '',
    date            TIMESTAMPTZ NOT NULL DEFAULT now(),
    start_time      TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    department      TEXT NOT NULL DEFAULT '',
    shift_type      TEXT NOT NULL DEFAULT 'Morning',
    notes           TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_shifts_staff ON shifts(staff_id);

-- ————————————————————————————————————————
-- 18. TIME_SLOTS  (doctor availability)
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS time_slots (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    doctor_id       TEXT NOT NULL,
    date            TIMESTAMPTZ NOT NULL DEFAULT now(),
    start_time      TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_booked       BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_ts_doctor ON time_slots(doctor_id);

-- ————————————————————————————————————————
-- 19. CHAT_SESSIONS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS chat_sessions (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    patient_id      TEXT NOT NULL,
    messages        JSONB NOT NULL DEFAULT '[]',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cs_patient ON chat_sessions(patient_id);

-- ————————————————————————————————————————
-- 20. CHAT_MESSAGES
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS chat_messages (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    session_id      TEXT NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role            TEXT NOT NULL DEFAULT 'user',
    content         TEXT NOT NULL DEFAULT '',
    timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
    suggested_specialty TEXT,
    urgency_level   TEXT
);
CREATE INDEX IF NOT EXISTS idx_cm_session ON chat_messages(session_id);

-- ————————————————————————————————————————
-- 21. NURSE_PATIENT_ASSIGNMENTS
-- ————————————————————————————————————————
CREATE TABLE IF NOT EXISTS nurse_patient_assignments (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    staff_id        TEXT NOT NULL,
    patient_id      TEXT NOT NULL,
    assigned_date   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_npa_staff ON nurse_patient_assignments(staff_id);

-- ————————————————————————————————————————
-- 22. ADMISSIONS  (inpatient management)
-- ————————————————————————————————————————
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

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescribed_medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE vital_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE beds ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurse_patient_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE admissions ENABLE ROW LEVEL SECURITY;

-- Allow the anon/service key to do everything for now
-- (In production, tighten these to per-user access)
DO $$ 
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN SELECT unnest(ARRAY[
        'users','patients','doctors','staff','departments',
        'appointments','prescriptions','prescribed_medicines',
        'lab_tests','lab_test_results','bills','bill_items',
        'vital_records','notifications','inventory_items',
        'beds','shifts','time_slots','chat_sessions',
        'chat_messages','nurse_patient_assignments','admissions'
    ])
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Allow all for anon" ON %I', tbl);
        EXECUTE format('CREATE POLICY "Allow all for anon" ON %I FOR ALL USING (true) WITH CHECK (true)', tbl);
    END LOOP;
END $$;

-- ============================================================
-- DONE
-- ============================================================


-- ############################################################
-- ## supabase_permissions.sql
-- ############################################################

-- ============================================================
-- MedNex – Supabase Permission Grants
-- Run this in Supabase Dashboard → SQL Editor
-- Fixes: "permission denied for schema public"
-- ============================================================

-- Grant schema access to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant full table access
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;

-- Grant sequence access (for auto-generated IDs)
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Ensure future tables also get these grants
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;


-- ############################################################
-- ## schema_migration_v2.sql
-- ############################################################

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


-- ############################################################
-- ## schema_migration_v3_rls_fix.sql
-- ############################################################

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


-- ############################################################
-- ## schema_migration_v4_bills_docs_fix.sql
-- ############################################################

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


-- ############################################################
-- ## schema_migration_v5_requires_otp.sql
-- ############################################################

-- ============================================================
-- Schema Migration V5 - Explicit OTP Column
-- Add a `requires_otp` boolean to the `users` table and 
-- automatically disable it for all existing staff members.
-- ============================================================

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS requires_otp BOOLEAN NOT NULL DEFAULT TRUE;

-- Disable OTP for all current staff (anyone who isn't a patient)
UPDATE users 
SET requires_otp = FALSE 
WHERE role != 'patient';


-- ############################################################
-- ## schema_migration_admissions.sql
-- ############################################################

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


-- ############################################################
-- ## supabase_inventory_requests.sql
-- ############################################################

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


-- ############################################################
-- ## create_doctor_blocks.sql
-- ############################################################

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


-- ############################################################
-- ## fix_appointments_schema.sql
-- ############################################################

-- ============================================================
-- MedNex – Fix Appointments Table Schema (v3 – bulletproof)
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- Step 1: Rename the enum column out of the way
ALTER TABLE appointments RENAME COLUMN status TO status_old;

-- Step 2: Add a new text column
ALTER TABLE appointments ADD COLUMN status text DEFAULT 'scheduled';

-- Step 3: Copy existing values (cast enum to text)
UPDATE appointments SET status = status_old::text WHERE status_old IS NOT NULL;

-- Step 4: Drop the old enum column
ALTER TABLE appointments DROP COLUMN status_old;

-- Step 5: Drop the enum type
DROP TYPE IF EXISTS appointment_status;

-- Step 6: Add missing columns the app model needs
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS billing_status text DEFAULT 'pending';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS cancellation_reason text;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS rating integer;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS review text;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS patient_name text DEFAULT '';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS doctor_name text DEFAULT '';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS specialty text DEFAULT 'General Medicine';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS type text DEFAULT 'consultation';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS notes text DEFAULT '';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

SELECT '✅ Appointments table schema fixed' AS result;


-- ############################################################
-- ## drop_fk_constraints.sql
-- ############################################################

-- ============================================================
-- MedNex – Drop Foreign Key Constraints on Appointments
-- Run this in Supabase Dashboard → SQL Editor
-- The app uses Firebase UIDs for doctor_id/patient_id which
-- don't match the doctors/patients table PKs, so FK constraints
-- block inserts. The app handles ID resolution in its load logic.
-- ============================================================

-- Drop all foreign key constraints on appointments
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'appointments'::regclass
          AND contype = 'f'
    ) LOOP
        EXECUTE format('ALTER TABLE appointments DROP CONSTRAINT %I', r.conname);
        RAISE NOTICE 'Dropped FK constraint: %', r.conname;
    END LOOP;
END $$;

SELECT '✅ All FK constraints dropped from appointments' AS result;


-- ############################################################
-- ## enable_realtime.sql
-- ############################################################

-- ============================================================
-- MedNex: Enable Supabase Realtime on all tables
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- Enable REPLICA IDENTITY FULL on every table so that Realtime
-- broadcasts the complete old+new row, not just primary keys.

ALTER TABLE users REPLICA IDENTITY FULL;
ALTER TABLE patients REPLICA IDENTITY FULL;
ALTER TABLE doctors REPLICA IDENTITY FULL;
ALTER TABLE staff REPLICA IDENTITY FULL;
ALTER TABLE appointments REPLICA IDENTITY FULL;
ALTER TABLE bills REPLICA IDENTITY FULL;
ALTER TABLE lab_tests REPLICA IDENTITY FULL;
ALTER TABLE vital_records REPLICA IDENTITY FULL;
ALTER TABLE beds REPLICA IDENTITY FULL;
ALTER TABLE inventory_items REPLICA IDENTITY FULL;
ALTER TABLE notifications REPLICA IDENTITY FULL;
ALTER TABLE chat_sessions REPLICA IDENTITY FULL;
ALTER TABLE chat_messages REPLICA IDENTITY FULL;
ALTER TABLE prescriptions REPLICA IDENTITY FULL;
ALTER TABLE admissions REPLICA IDENTITY FULL;
ALTER TABLE vitals_requests REPLICA IDENTITY FULL;
ALTER TABLE nurse_patient_assignments REPLICA IDENTITY FULL;

-- Add tables to the supabase_realtime publication
-- (safe to re-run — will skip if already added)

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT unnest(ARRAY[
      'users','patients','doctors','staff',
      'appointments','bills','lab_tests','vital_records',
      'beds','inventory_items','notifications',
      'chat_sessions','chat_messages','prescriptions',
      'admissions','vitals_requests','nurse_patient_assignments'
    ])
  LOOP
    BEGIN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I', tbl);
      RAISE NOTICE 'Added % to supabase_realtime', tbl;
    EXCEPTION WHEN duplicate_object THEN
      RAISE NOTICE '% already in publication', tbl;
    END;
  END LOOP;
END $$;

SELECT '✅ Realtime enabled on all MedNex tables' AS status;


-- ############################################################
-- ## disable_rls.sql
-- ############################################################

-- ============================================================
-- MedNex – Disable RLS on all tables (development mode)
-- Run this in Supabase Dashboard → SQL Editor
-- This ensures NO insert/select is silently blocked by RLS.
-- ============================================================

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE patients DISABLE ROW LEVEL SECURITY;
ALTER TABLE doctors DISABLE ROW LEVEL SECURITY;
ALTER TABLE staff DISABLE ROW LEVEL SECURITY;
ALTER TABLE appointments DISABLE ROW LEVEL SECURITY;
ALTER TABLE bills DISABLE ROW LEVEL SECURITY;
ALTER TABLE lab_tests DISABLE ROW LEVEL SECURITY;
ALTER TABLE vital_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE beds DISABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE admissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE vitals_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE nurse_patient_assignments DISABLE ROW LEVEL SECURITY;

SELECT '✅ RLS disabled on all MedNex tables' AS status;


-- ############################################################
-- ## supabase_seed_data.sql
-- ############################################################

-- ============================================================
-- MedNex Supabase Seed Data
-- Run this AFTER supabase_schema.sql and supabase_permissions.sql
-- 
-- Note: User IDs here are placeholders. The SeedDataService in the
-- app will create the actual Firebase users and sync profiles.
-- This script seeds supporting data: departments, inventory,
-- sample appointments, prescriptions, lab tests, etc.
-- ============================================================

-- ============================================================
-- 1. DEPARTMENTS
-- Columns: id, name, head_doctor_id, head_doctor_name, staff_count,
--          location, description, is_active, created_at
-- ============================================================
INSERT INTO departments (id, name, description, location, staff_count, is_active)
VALUES
    ('dept1', 'General Medicine', 'Primary care and internal medicine', 'Floor 1, Wing A', 8, true),
    ('dept2', 'Cardiology', 'Heart and cardiovascular care', 'Floor 2, Wing B', 5, true),
    ('dept3', 'Pediatrics', 'Child and adolescent medicine', 'Floor 1, Wing C', 6, true),
    ('dept4', 'Orthopedics', 'Bone, joint, and muscle care', 'Floor 3, Wing A', 4, true),
    ('dept5', 'Dermatology', 'Skin, hair, and nail care', 'Floor 2, Wing A', 3, true),
    ('dept6', 'Neurology', 'Brain and nervous system', 'Floor 3, Wing B', 4, true),
    ('dept7', 'Pathology', 'Laboratory testing and diagnostics', 'Basement 1', 5, true),
    ('dept8', 'Pharmacy', 'Medicine dispensing and counseling', 'Ground Floor', 4, true),
    ('dept9', 'Emergency', '24/7 emergency care', 'Ground Floor, Wing D', 10, true),
    ('dept10', 'Administration', 'Hospital administration', 'Floor 4', 6, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. INVENTORY ITEMS
-- Columns: id, name, category, stock, reorder_level, unit_price,
--          supplier, last_updated
-- ============================================================
INSERT INTO inventory_items (id, name, category, stock, reorder_level, unit_price, supplier)
VALUES
    ('inv1', 'Paracetamol 500mg', 'Medication', 500, 100, 2.50, 'PharmaCorp India'),
    ('inv2', 'Amoxicillin 250mg', 'Medication', 350, 80, 8.00, 'MediPharma Ltd'),
    ('inv3', 'Surgical Gloves (L)', 'Consumable', 2000, 500, 15.00, 'SafeHands Pvt Ltd'),
    ('inv4', 'N95 Masks', 'Consumable', 1500, 300, 25.00, 'BreatheEasy Co'),
    ('inv5', 'IV Saline 500ml', 'Consumable', 200, 50, 45.00, 'AquaMed Solutions'),
    ('inv6', 'Omeprazole 20mg', 'Medication', 400, 100, 5.50, 'GastroPharm Ltd'),
    ('inv7', 'Digital Thermometer', 'Equipment', 50, 10, 350.00, 'MedEquip India'),
    ('inv8', 'Blood Glucose Strips', 'Consumable', 800, 200, 18.00, 'DiabeCheck Co'),
    ('inv9', 'Metformin 500mg', 'Medication', 600, 150, 4.00, 'DiabetaCare Pharma'),
    ('inv10', 'Syringes 5ml', 'Consumable', 3000, 500, 8.00, 'InjectSafe Ltd'),
    ('inv11', 'Azithromycin 500mg', 'Medication', 25, 80, 12.00, 'AntibioPharm Ltd'),
    ('inv12', 'Surgical Masks', 'Consumable', 150, 300, 10.00, 'SafeGuard Pvt Ltd'),
    ('inv13', 'Ibuprofen 400mg', 'Medication', 200, 100, 3.00, 'PainRelief Pharma'),
    ('inv14', 'Cetrizine 10mg', 'Medication', 450, 100, 2.00, 'AllergyFree Ltd'),
    ('inv15', 'Bandage Rolls', 'Consumable', 600, 100, 20.00, 'WoundCare India')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. BEDS
-- Columns: id, number, ward, floor, status, patient_name
-- ============================================================
INSERT INTO beds (id, number, ward, floor, status, patient_name)
VALUES
    ('bed-gwa-01', 'GWA-01', 'General Ward A', '1', 'available', NULL),
    ('bed-gwa-02', 'GWA-02', 'General Ward A', '1', 'occupied', 'Rahul Sharma'),
    ('bed-gwa-03', 'GWA-03', 'General Ward A', '1', 'available', NULL),
    ('bed-gwa-04', 'GWA-04', 'General Ward A', '1', 'occupied', 'Priya Mehta'),
    ('bed-gwb-01', 'GWB-01', 'General Ward B', '1', 'available', NULL),
    ('bed-gwb-02', 'GWB-02', 'General Ward B', '1', 'occupied', 'Amit Kumar'),
    ('bed-gwb-03', 'GWB-03', 'General Ward B', '1', 'maintenance', NULL),
    ('bed-icu-01', 'ICU-01', 'ICU', '2', 'occupied', 'Neha Tiwari'),
    ('bed-icu-02', 'ICU-02', 'ICU', '2', 'available', NULL),
    ('bed-icu-03', 'ICU-03', 'ICU', '2', 'occupied', 'Suresh Patel'),
    ('bed-icu-04', 'ICU-04', 'ICU', '2', 'reserved', NULL),
    ('bed-ped-01', 'PED-01', 'Pediatric', '1', 'available', NULL),
    ('bed-ped-02', 'PED-02', 'Pediatric', '1', 'occupied', 'Baby Arjun'),
    ('bed-mat-01', 'MAT-01', 'Maternity', '2', 'available', NULL),
    ('bed-mat-02', 'MAT-02', 'Maternity', '2', 'occupied', 'Anita Verma'),
    ('bed-sur-01', 'SUR-01', 'Surgical', '3', 'available', NULL),
    ('bed-sur-02', 'SUR-02', 'Surgical', '3', 'occupied', 'Rajesh Gupta')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. SHIFTS
-- Columns: id, staff_id, staff_name, date, start_time, end_time,
--          department, shift_type, notes
-- (date/start_time/end_time are TIMESTAMPTZ)
-- ============================================================
INSERT INTO shifts (id, staff_id, staff_name, date, start_time, end_time, shift_type, department)
VALUES
    ('shift1', 'DOC001', 'Dr. Sarah Smith', CURRENT_DATE, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '16:00', 'Morning', 'General Medicine'),
    ('shift2', 'NRS001', 'Emily Davis', CURRENT_DATE, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '16:00', 'Morning', 'Nursing'),
    ('shift3', 'LAB001', 'Michael Chen', CURRENT_DATE, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '17:00', 'Morning', 'Pathology'),
    ('shift4', 'PHR001', 'Lisa Rodriguez', CURRENT_DATE, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '17:00', 'Morning', 'Pharmacy'),
    ('shift5', 'DOC001', 'Dr. Sarah Smith', CURRENT_DATE + 1, CURRENT_DATE + 1 + TIME '08:00', CURRENT_DATE + 1 + TIME '16:00', 'Morning', 'General Medicine'),
    ('shift6', 'NRS001', 'Emily Davis', CURRENT_DATE + 1, CURRENT_DATE + 1 + TIME '16:00', CURRENT_DATE + 2 + TIME '00:00', 'Evening', 'Nursing'),
    ('shift7', 'LAB001', 'Michael Chen', CURRENT_DATE + 2, CURRENT_DATE + 2 + TIME '09:00', CURRENT_DATE + 2 + TIME '17:00', 'Morning', 'Pathology')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 5. TIME SLOTS for demo doctor (next 7 weekdays)
-- Columns: id, doctor_id, date, start_time, end_time, is_booked
-- (date/start_time/end_time are TIMESTAMPTZ)
-- ============================================================
DO $$
DECLARE
    d DATE;
    slot_start TIMESTAMPTZ;
    slot_end TIMESTAMPTZ;
    slot_id TEXT;
    doctor_id TEXT := 'DOC001';
BEGIN
    FOR i IN 0..6 LOOP
        d := CURRENT_DATE + i;
        -- Skip weekends
        IF EXTRACT(DOW FROM d) NOT IN (0, 6) THEN
            FOR h IN 9..16 LOOP
                slot_id := 'ts_' || TO_CHAR(d, 'YYYYMMDD') || '_' || LPAD(h::TEXT, 2, '0');
                slot_start := d + (h || ' hours')::INTERVAL;
                slot_end := d + (h || ' hours')::INTERVAL + INTERVAL '30 minutes';
                INSERT INTO time_slots (id, doctor_id, date, start_time, end_time, is_booked)
                VALUES (slot_id, doctor_id, d, slot_start, slot_end, false)
                ON CONFLICT (id) DO NOTHING;
            END LOOP;
        END IF;
    END LOOP;
END $$;

-- ============================================================
-- Done! Now run the app and it will create Firebase users and
-- sync profiles via SeedDataService.
-- ============================================================

SELECT 'Seed data inserted successfully!' AS status;
SELECT COUNT(*) AS departments FROM departments;
SELECT COUNT(*) AS inventory_items FROM inventory_items;
SELECT COUNT(*) AS beds FROM beds;
SELECT COUNT(*) AS shifts FROM shifts;
SELECT COUNT(*) AS time_slots FROM time_slots;
