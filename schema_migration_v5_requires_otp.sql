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
