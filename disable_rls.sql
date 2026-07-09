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
