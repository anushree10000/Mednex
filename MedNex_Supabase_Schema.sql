-- MedNex Supabase Schema Migration
-- Run this SQL in the Supabase SQL Editor to create all tables.

-- ============================================================
-- 1. USERS TABLE (linked to Firebase Auth UID)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,  -- Firebase Auth UID
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'patient',
    display_name TEXT NOT NULL,
    profile_image_url TEXT,
    phone_number TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- ============================================================
-- 2. DEPARTMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS departments (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    head_doctor_id TEXT,
    head_doctor_name TEXT,
    staff_count INTEGER NOT NULL DEFAULT 0,
    location TEXT DEFAULT '',
    description TEXT DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 3. DOCTORS
-- ============================================================
CREATE TABLE IF NOT EXISTS doctors (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    specialty TEXT NOT NULL DEFAULT 'General Medicine',
    experience INTEGER NOT NULL DEFAULT 0,
    license_number TEXT DEFAULT '',
    consultation_fee DECIMAL(10,2) NOT NULL DEFAULT 500.00,
    department_id TEXT REFERENCES departments(id),
    rating DOUBLE PRECISION NOT NULL DEFAULT 4.5,
    total_ratings INTEGER NOT NULL DEFAULT 0,
    bio TEXT DEFAULT '',
    education TEXT DEFAULT '',
    is_available BOOLEAN NOT NULL DEFAULT true,
    UNIQUE(user_id)
);

-- ============================================================
-- 4. DOCTOR LANGUAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS doctor_languages (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    doctor_id TEXT NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    language TEXT NOT NULL
);

-- ============================================================
-- 5. TIME SLOTS (Doctor Availability)
-- ============================================================
CREATE TABLE IF NOT EXISTS time_slots (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    doctor_id TEXT NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_booked BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_time_slots_doctor_date ON time_slots(doctor_id, date);

-- ============================================================
-- 6. PATIENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS patients (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL DEFAULT '',
    last_name TEXT NOT NULL DEFAULT '',
    date_of_birth DATE,
    gender TEXT DEFAULT 'other',
    phone TEXT DEFAULT '',
    address TEXT DEFAULT '',
    city TEXT DEFAULT '',
    state TEXT DEFAULT '',
    zip_code TEXT DEFAULT '',
    UNIQUE(user_id)
);

-- ============================================================
-- 7. MEDICAL INFO (1:1 with patients)
-- ============================================================
CREATE TABLE IF NOT EXISTS medical_info (
    patient_id TEXT PRIMARY KEY REFERENCES patients(id) ON DELETE CASCADE,
    blood_type TEXT DEFAULT 'Unknown',
    height_cm DOUBLE PRECISION,
    weight_kg DOUBLE PRECISION
);

-- ============================================================
-- 8. PATIENT ARRAYS (allergies, conditions, medications)
-- ============================================================
CREATE TABLE IF NOT EXISTS patient_allergies (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    allergy TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_chronic_conditions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    condition TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_current_medications (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    medication TEXT NOT NULL
);

-- ============================================================
-- 9. EMERGENCY CONTACTS
-- ============================================================
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    relationship TEXT DEFAULT '',
    phone TEXT DEFAULT ''
);

-- ============================================================
-- 10. APPOINTMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS appointments (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id),
    patient_name TEXT DEFAULT '',
    doctor_id TEXT NOT NULL REFERENCES doctors(id),
    doctor_name TEXT DEFAULT '',
    specialty TEXT DEFAULT '',
    date_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled',
    type TEXT NOT NULL DEFAULT 'consultation',
    notes TEXT DEFAULT '',
    prescription_id TEXT,
    billing_status TEXT DEFAULT 'pending',
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_date ON appointments(date_time);

-- ============================================================
-- 11. PRESCRIPTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS prescriptions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    appointment_id TEXT REFERENCES appointments(id),
    patient_id TEXT NOT NULL REFERENCES patients(id),
    patient_name TEXT DEFAULT '',
    doctor_id TEXT NOT NULL REFERENCES doctors(id),
    doctor_name TEXT DEFAULT '',
    diagnosis TEXT DEFAULT '',
    notes TEXT DEFAULT '',
    pdf_url TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 12. PRESCRIBED MEDICINES
-- ============================================================
CREATE TABLE IF NOT EXISTS prescribed_medicines (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    prescription_id TEXT NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT DEFAULT '',
    frequency TEXT DEFAULT 'Once Daily',
    duration TEXT DEFAULT '',
    instructions TEXT DEFAULT '',
    is_taken BOOLEAN NOT NULL DEFAULT false
);

-- ============================================================
-- 13. MEDICINES CATALOG
-- ============================================================
CREATE TABLE IF NOT EXISTS medicines (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    generic_name TEXT DEFAULT '',
    category TEXT DEFAULT '',
    manufacturer TEXT DEFAULT ''
);

-- ============================================================
-- 14. BILLS
-- ============================================================
CREATE TABLE IF NOT EXISTS bills (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    appointment_id TEXT REFERENCES appointments(id),
    patient_id TEXT NOT NULL REFERENCES patients(id),
    patient_name TEXT DEFAULT '',
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_mode TEXT,
    status TEXT NOT NULL DEFAULT 'unpaid',
    invoice_pdf_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    paid_at TIMESTAMPTZ
);

CREATE INDEX idx_bills_patient ON bills(patient_id);

-- ============================================================
-- 15. BILL ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS bill_items (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    bill_id TEXT NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0
);

-- ============================================================
-- 16. LAB TESTS
-- ============================================================
CREATE TABLE IF NOT EXISTS lab_tests (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id),
    patient_name TEXT DEFAULT '',
    doctor_id TEXT NOT NULL REFERENCES doctors(id),
    doctor_name TEXT DEFAULT '',
    test_name TEXT NOT NULL,
    test_category TEXT NOT NULL DEFAULT 'Blood Work',
    status TEXT NOT NULL DEFAULT 'pending',
    priority TEXT NOT NULL DEFAULT 'routine',
    notes TEXT DEFAULT '',
    report_pdf_url TEXT,
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

-- ============================================================
-- 17. LAB TEST RESULTS
-- ============================================================
CREATE TABLE IF NOT EXISTS lab_test_results (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    lab_test_id TEXT NOT NULL REFERENCES lab_tests(id) ON DELETE CASCADE,
    parameter_name TEXT NOT NULL,
    value TEXT DEFAULT '',
    unit TEXT DEFAULT '',
    normal_range TEXT DEFAULT '',
    is_abnormal BOOLEAN NOT NULL DEFAULT false
);

-- ============================================================
-- 18. VITAL RECORDS
-- ============================================================
CREATE TABLE IF NOT EXISTS vital_records (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id),
    recorded_by TEXT DEFAULT '',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    bp_systolic DOUBLE PRECISION,
    bp_diastolic DOUBLE PRECISION,
    heart_rate DOUBLE PRECISION,
    temperature_f DOUBLE PRECISION,
    respiratory_rate DOUBLE PRECISION,
    oxygen_saturation DOUBLE PRECISION,
    weight_kg DOUBLE PRECISION,
    height_cm DOUBLE PRECISION,
    blood_glucose DOUBLE PRECISION,
    notes TEXT DEFAULT ''
);

CREATE INDEX idx_vitals_patient ON vital_records(patient_id);

-- ============================================================
-- 19. STAFF
-- ============================================================
CREATE TABLE IF NOT EXISTS staff (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'nurse',
    department_id TEXT REFERENCES departments(id),
    department_name TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    email TEXT DEFAULT '',
    shift TEXT DEFAULT 'Morning',
    join_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    qualifications TEXT DEFAULT '',
    specialization TEXT,
    UNIQUE(user_id)
);

-- ============================================================
-- 20. SHIFTS
-- ============================================================
CREATE TABLE IF NOT EXISTS shifts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    staff_id TEXT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    staff_name TEXT DEFAULT '',
    date DATE NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    department TEXT DEFAULT '',
    shift_type TEXT NOT NULL DEFAULT 'Morning',
    notes TEXT DEFAULT ''
);

-- ============================================================
-- 21. INVENTORY
-- ============================================================
CREATE TABLE IF NOT EXISTS inventory_items (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Medication',
    stock INTEGER NOT NULL DEFAULT 0,
    reorder_level INTEGER NOT NULL DEFAULT 10,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    supplier TEXT DEFAULT '',
    last_updated TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 22. BEDS
-- ============================================================
CREATE TABLE IF NOT EXISTS beds (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    number TEXT NOT NULL,
    ward TEXT NOT NULL,
    floor TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'available',
    patient_name TEXT
);

-- ============================================================
-- 23. NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL DEFAULT 'general',
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    related_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);

-- ============================================================
-- 24. CHAT SESSIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_sessions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 25. CHAT MESSAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    session_id TEXT NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'user',
    content TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    suggested_specialty TEXT,
    urgency_level TEXT
);

-- ============================================================
-- 26. NURSE-PATIENT ASSIGNMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS nurse_patient_assignments (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    staff_id TEXT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE(staff_id, patient_id, assigned_date)
);


-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE vital_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

-- Users: can read own profile
CREATE POLICY "Users can read own profile" ON users
    FOR SELECT USING (id = auth.uid()::text);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (id = auth.uid()::text);

-- Patients: can read own data
CREATE POLICY "Patients read own data" ON patients
    FOR SELECT USING (user_id = auth.uid()::text);

-- Appointments: patients see own, doctors see own
CREATE POLICY "Users see own appointments" ON appointments
    FOR SELECT USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
        OR doctor_id IN (SELECT id FROM doctors WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Patients can create appointments" ON appointments
    FOR INSERT WITH CHECK (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
    );

-- Prescriptions: patients see own, doctors see own
CREATE POLICY "Users see own prescriptions" ON prescriptions
    FOR SELECT USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
        OR doctor_id IN (SELECT id FROM doctors WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Doctors can create prescriptions" ON prescriptions
    FOR INSERT WITH CHECK (
        doctor_id IN (SELECT id FROM doctors WHERE user_id = auth.uid()::text)
    );

-- Bills: patients see own
CREATE POLICY "Patients see own bills" ON bills
    FOR SELECT USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
    );

-- Lab tests: patients see own, doctors see own
CREATE POLICY "Users see own lab tests" ON lab_tests
    FOR SELECT USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
        OR doctor_id IN (SELECT id FROM doctors WHERE user_id = auth.uid()::text)
    );

-- Vitals: patients see own
CREATE POLICY "Patients see own vitals" ON vital_records
    FOR SELECT USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()::text)
    );

-- Notifications: users see own
CREATE POLICY "Users see own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid()::text);

CREATE POLICY "Users update own notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid()::text);

-- Admin bypass: admins can see everything
CREATE POLICY "Admins full access users" ON users
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

CREATE POLICY "Admins full access appointments" ON appointments
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

CREATE POLICY "Admins full access staff" ON staff
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

CREATE POLICY "Admins full access bills" ON bills
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

-- Doctors: can write to prescriptions, lab_tests, vital_records
CREATE POLICY "Doctors write vitals" ON vital_records
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM doctors WHERE user_id = auth.uid()::text)
    );

CREATE POLICY "Doctors write lab tests" ON lab_tests
    FOR INSERT WITH CHECK (
        doctor_id IN (SELECT id FROM doctors WHERE user_id = auth.uid()::text)
    );
