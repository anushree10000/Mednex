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
