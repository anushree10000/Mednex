-- ============================================================
-- MedNex – Sync Staff Doctors → Doctors Table
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- Step 1: Fix staff.user_id to match the real users table ID
--         (resolves placeholder user_ids like 'demo_doc_uid')
UPDATE staff s
SET user_id = u.id
FROM users u
WHERE u.email = s.email
  AND s.role = 'doctor'
  AND s.user_id != u.id;

-- Step 2: Insert into doctors table using the corrected user_id
INSERT INTO doctors (id, user_id, name, specialty, experience, license_number, consultation_fee, department_id, rating, total_ratings, available_slots, bio, education, languages, is_available)
SELECT
    s.id,
    s.user_id,
    s.name,
    COALESCE(NULLIF(s.specialization, ''), 'General Medicine'),
    0,
    '',
    500,
    NULLIF(s.department_id, ''),
    5.0,
    0,
    '[]'::JSONB,
    '',
    COALESCE(s.qualifications, ''),
    '["English"]'::JSONB,
    TRUE
FROM staff s
WHERE s.role = 'doctor'
  AND EXISTS (SELECT 1 FROM users u WHERE u.id = s.user_id)
ON CONFLICT (id) DO NOTHING;

-- Step 3: Show results
SELECT d.id, d.user_id, d.name, d.specialty, d.department_id
FROM doctors d
JOIN staff s ON s.id = d.id
WHERE s.role = 'doctor';
