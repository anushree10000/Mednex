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
