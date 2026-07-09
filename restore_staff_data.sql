-- ============================================================
-- MedNex - Restore Default Staff Data
-- Run this in Supabase Dashboard → SQL Editor if the staff 
-- table is empty due to a reset or bypassing Firebase Auth.
-- ============================================================

INSERT INTO staff (id, user_id, name, email, role, department_id, department_name, phone, shift, is_active)
VALUES
    ('DOC001', 'demo_doc_uid', 'Dr. Sarah Smith', 'dr.smith@mednex.com', 'doctor', 'dept1', 'General Medicine', '+91 98765 11111', 'Morning', true),
    ('ADM001', 'demo_admin_uid', 'James Wilson', 'admin@mednex.com', 'admin', 'dept10', 'Administration', '+91 98765 22222', 'Morning', true),
    ('NRS001', 'demo_nurse_uid', 'Emily Davis', 'nurse@mednex.com', 'nurse', 'dept1', 'Nursing', '+91 98765 33333', 'Morning', true),
    ('LAB001', 'demo_lab_uid', 'Michael Chen', 'lab@mednex.com', 'lab_technician', 'dept7', 'Pathology', '+91 98765 44444', 'Morning', true),
    ('PHR001', 'demo_pharma_uid', 'Lisa Rodriguez', 'pharma@mednex.com', 'pharmacist', 'dept8', 'Pharmacy', '+91 98765 55555', 'Morning', true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    department_id = EXCLUDED.department_id,
    department_name = EXCLUDED.department_name;

-- Note: user_id is set to a placeholder. If you look up real Firebase UIDs in your 'users' table,
-- you can UPDATE staff SET user_id = 'your-real-uid' WHERE id = 'DOC001';
