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
