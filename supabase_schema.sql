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
