-- ============================================================
-- MedNex – Schema migration v6: real row-level security + live updates
--
-- What this does
--   1. Lets Supabase trust Firebase logins (third-party auth) and
--      identifies the user by the Firebase UID in the JWT "sub" claim.
--   2. Turns row-level security (RLS) ON for every table and replaces
--      the old development policies with role-based ones:
--        • patients see and change only their own rows
--        • staff (doctor, nurse, lab, pharmacy, reception, accounts)
--          work on hospital data
--        • admins manage users, staff, departments and doctors
--   3. Removes the blanket "anon can do everything" grants.
--   4. Lets staff log in with a staff ID without exposing the staff table.
--   5. Makes sure the tables the app listens to are in the realtime
--      publication.
--
-- BEFORE running this, finish steps 1–3 in SECURITY_SETUP.md
-- (Firebase third-party auth in the Supabase dashboard, and the
-- role: authenticated claim on Firebase tokens). Running it earlier
-- will block the app until those steps are done.
--
-- To undo in an emergency, run disable_rls.sql and supabase_permissions.sql.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 0. Audit log table (SecurityService.logAuditEvent writes here;
--    column names match the app's camelCase JSON)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id           TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "timestamp"  TIMESTAMPTZ NOT NULL DEFAULT now(),
    "userId"     TEXT NOT NULL,
    action       TEXT NOT NULL,
    resource     TEXT NOT NULL,
    "resourceId" TEXT,
    "ipAddress"  TEXT,
    details      TEXT
);

-- ------------------------------------------------------------
-- 1. Helper functions, in a schema the REST API does not expose
-- ------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS app_private;
REVOKE ALL ON SCHEMA app_private FROM PUBLIC;
GRANT USAGE ON SCHEMA app_private TO authenticated;

-- The signed-in user's Firebase UID (users.id in MedNex)
CREATE OR REPLACE FUNCTION app_private.uid()
RETURNS TEXT LANGUAGE sql STABLE SET search_path = '' AS $$
    SELECT nullif(auth.jwt() ->> 'sub', '')
$$;

-- Only accept tokens issued for THIS Firebase project or THIS Supabase project.
-- (Firebase signs tokens for every project with the same keys, so this check matters.)
CREATE OR REPLACE FUNCTION app_private.trusted_jwt()
RETURNS BOOLEAN LANGUAGE sql STABLE SET search_path = '' AS $$
    SELECT coalesce(
        (    auth.jwt() ->> 'iss' = 'https://securetoken.google.com/mednex-56348'
         AND auth.jwt() ->> 'aud' = 'mednex-56348')
        OR auth.jwt() ->> 'iss' = 'https://eqigjryyhjwimadhzxzp.supabase.co/auth/v1',
        false)
$$;

-- The signed-in user's MedNex role, read from public.users
CREATE OR REPLACE FUNCTION app_private.role()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT u.role FROM public.users u WHERE u.id = app_private.uid()
$$;

CREATE OR REPLACE FUNCTION app_private.is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SET search_path = '' AS $$
    SELECT coalesce(app_private.role() <> 'patient', false)
$$;

CREATE OR REPLACE FUNCTION app_private.is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SET search_path = '' AS $$
    SELECT coalesce(app_private.role() = 'admin', false)
$$;

-- Patient ids that belong to the signed-in user.
-- The app stores the Firebase UID as patient_id; older rows may use patients.id.
CREATE OR REPLACE FUNCTION app_private.owns_patient(p_patient_id TEXT)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT p_patient_id IS NOT NULL AND (
           p_patient_id = app_private.uid()
        OR EXISTS (SELECT 1 FROM public.patients p
                   WHERE p.id = p_patient_id AND p.user_id = app_private.uid()))
$$;

-- The role an admin gave this email when adding them as staff (NULL if not invited)
CREATE OR REPLACE FUNCTION app_private.invited_role(p_email TEXT)
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT s.role FROM public.staff s
    WHERE lower(s.email) = lower(p_email) AND coalesce(s.is_active, true)
    LIMIT 1
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA app_private FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_private TO authenticated;

-- Staff-ID login: the app turns a staff ID into an email before signing in.
-- Exposed as an RPC so anonymous users never need read access to the staff table.
CREATE OR REPLACE FUNCTION public.staff_email_for_id(p_staff_id TEXT)
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT s.email FROM public.staff s
    WHERE s.id = p_staff_id AND coalesce(s.is_active, true)
$$;
REVOKE ALL ON FUNCTION public.staff_email_for_id(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.staff_email_for_id(TEXT) TO anon, authenticated;

-- ------------------------------------------------------------
-- 2. Table privileges: no more blanket access for the public key
-- ------------------------------------------------------------
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES    FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ------------------------------------------------------------
-- 3. Drop every old policy, then switch RLS on for every table
-- ------------------------------------------------------------
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public' LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;

    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.tablename);
        -- Every request must carry a token from our Firebase or Supabase project.
        EXECUTE format(
            'CREATE POLICY trusted_token_only ON public.%I AS RESTRICTIVE FOR ALL TO authenticated '
            'USING (app_private.trusted_jwt()) WITH CHECK (app_private.trusted_jwt())',
            r.tablename);
    END LOOP;
END $$;

-- ------------------------------------------------------------
-- 4. Staff work on hospital data
--    (every table except accounts, staff records, directory tables,
--     audit logs and private patient chat, which have their own rules)
-- ------------------------------------------------------------
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT tablename FROM pg_tables
        WHERE schemaname = 'public'
          AND tablename NOT IN ('users', 'staff', 'departments', 'doctors',
                                'audit_logs', 'chat_sessions', 'chat_messages')
    LOOP
        EXECUTE format(
            'CREATE POLICY staff_manage ON public.%I FOR ALL TO authenticated '
            'USING (app_private.is_staff()) WITH CHECK (app_private.is_staff())',
            r.tablename);
    END LOOP;
END $$;

-- ------------------------------------------------------------
-- 5. Directory data every signed-in user can read (needed for booking)
-- ------------------------------------------------------------
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['doctors', 'departments', 'time_slots', 'doctor_blocks',
                             'medicines', 'doctor_languages'] LOOP
        IF to_regclass('public.' || t) IS NOT NULL THEN
            EXECUTE format('CREATE POLICY directory_read ON public.%I FOR SELECT TO authenticated USING (true)', t);
        END IF;
    END LOOP;
END $$;

-- Admins manage staff, departments and doctors; staff can see the staff list
CREATE POLICY admin_manage ON public.staff       FOR ALL TO authenticated USING (app_private.is_admin()) WITH CHECK (app_private.is_admin());
CREATE POLICY admin_manage ON public.departments FOR ALL TO authenticated USING (app_private.is_admin()) WITH CHECK (app_private.is_admin());
CREATE POLICY admin_manage ON public.doctors     FOR ALL TO authenticated USING (app_private.is_admin()) WITH CHECK (app_private.is_admin());
CREATE POLICY staff_read   ON public.staff       FOR SELECT TO authenticated USING (app_private.is_staff());

-- Doctors can edit their own doctor profile
CREATE POLICY doctor_self_update ON public.doctors FOR UPDATE TO authenticated
    USING (user_id = app_private.uid()) WITH CHECK (user_id = app_private.uid());

-- ------------------------------------------------------------
-- 6. User accounts
-- ------------------------------------------------------------
-- Read your own account; staff can read accounts (names on screens)
CREATE POLICY users_read ON public.users FOR SELECT TO authenticated
    USING (id = app_private.uid() OR app_private.is_staff());

-- Create your own account: as a patient, or with the staff role an admin invited you for.
-- (Stops anyone signing up as "admin" from the app.)
CREATE POLICY users_self_create ON public.users FOR INSERT TO authenticated
    WITH CHECK (
        id = app_private.uid()
        AND (role = 'patient' OR role = app_private.invited_role(email))
    );

-- Update your own account, but never your own role
CREATE POLICY users_self_update ON public.users FOR UPDATE TO authenticated
    USING (id = app_private.uid())
    WITH CHECK (id = app_private.uid() AND role = app_private.role());

CREATE POLICY admin_manage ON public.users FOR ALL TO authenticated
    USING (app_private.is_admin()) WITH CHECK (app_private.is_admin());

-- ------------------------------------------------------------
-- 7. Patients: only their own records
-- ------------------------------------------------------------
CREATE POLICY patient_self ON public.patients FOR ALL TO authenticated
    USING (user_id = app_private.uid() OR id = app_private.uid())
    WITH CHECK (user_id = app_private.uid());

DO $$
DECLARE t TEXT;
BEGIN
    -- Read own rows
    FOREACH t IN ARRAY ARRAY['appointments', 'prescriptions', 'lab_tests', 'vital_records', 'bills',
                             'admissions', 'patient_documents', 'chat_sessions', 'vitals_requests',
                             'patient_allergies', 'patient_chronic_conditions',
                             'patient_current_medications', 'emergency_contacts', 'medical_info'] LOOP
        IF to_regclass('public.' || t) IS NOT NULL THEN
            EXECUTE format('CREATE POLICY patient_read_own ON public.%I FOR SELECT TO authenticated '
                           'USING (app_private.owns_patient(patient_id))', t);
        END IF;
    END LOOP;

    -- Create own rows (book appointments, request lab tests, chat, upload documents, edit health info)
    FOREACH t IN ARRAY ARRAY['appointments', 'lab_tests', 'chat_sessions', 'patient_documents',
                             'patient_allergies', 'patient_chronic_conditions',
                             'patient_current_medications', 'emergency_contacts', 'medical_info'] LOOP
        IF to_regclass('public.' || t) IS NOT NULL THEN
            EXECUTE format('CREATE POLICY patient_create_own ON public.%I FOR INSERT TO authenticated '
                           'WITH CHECK (app_private.owns_patient(patient_id))', t);
        END IF;
    END LOOP;

    -- Update own rows (cancel or reschedule, pay bills, edit health info)
    FOREACH t IN ARRAY ARRAY['appointments', 'bills', 'chat_sessions', 'patient_documents',
                             'patient_allergies', 'patient_chronic_conditions',
                             'patient_current_medications', 'emergency_contacts', 'medical_info'] LOOP
        IF to_regclass('public.' || t) IS NOT NULL THEN
            EXECUTE format('CREATE POLICY patient_update_own ON public.%I FOR UPDATE TO authenticated '
                           'USING (app_private.owns_patient(patient_id)) '
                           'WITH CHECK (app_private.owns_patient(patient_id))', t);
        END IF;
    END LOOP;

    -- Delete own health-info rows and documents
    FOREACH t IN ARRAY ARRAY['patient_documents', 'patient_allergies', 'patient_chronic_conditions',
                             'patient_current_medications', 'emergency_contacts'] LOOP
        IF to_regclass('public.' || t) IS NOT NULL THEN
            EXECUTE format('CREATE POLICY patient_delete_own ON public.%I FOR DELETE TO authenticated '
                           'USING (app_private.owns_patient(patient_id))', t);
        END IF;
    END LOOP;
END $$;

-- Child rows follow their parent record
CREATE POLICY patient_read_own ON public.prescribed_medicines FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.prescriptions p
                   WHERE p.id = prescription_id AND app_private.owns_patient(p.patient_id)));

CREATE POLICY patient_read_own ON public.bill_items FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.bills b
                   WHERE b.id = bill_id AND app_private.owns_patient(b.patient_id)));

CREATE POLICY patient_read_own ON public.lab_test_results FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.lab_tests l
                   WHERE l.id = lab_test_id AND app_private.owns_patient(l.patient_id)));

DO $$
BEGIN
    IF to_regclass('public.chat_messages') IS NOT NULL THEN
        CREATE POLICY patient_own_chat ON public.chat_messages FOR ALL TO authenticated
            USING (EXISTS (SELECT 1 FROM public.chat_sessions s
                           WHERE s.id = session_id AND app_private.owns_patient(s.patient_id)))
            WITH CHECK (EXISTS (SELECT 1 FROM public.chat_sessions s
                                WHERE s.id = session_id AND app_private.owns_patient(s.patient_id)));
    END IF;
END $$;

-- ------------------------------------------------------------
-- 8. Notifications and audit logs
-- ------------------------------------------------------------
CREATE POLICY own_notifications ON public.notifications FOR ALL TO authenticated
    USING (user_id = app_private.uid()) WITH CHECK (user_id = app_private.uid());

CREATE POLICY write_own_audit ON public.audit_logs FOR INSERT TO authenticated
    WITH CHECK ("userId" = app_private.uid());
CREATE POLICY admin_read_audit ON public.audit_logs FOR SELECT TO authenticated
    USING (app_private.is_admin());

-- ------------------------------------------------------------
-- 9. Live updates: make sure the tables the app listens to are published.
--    Realtime applies the policies above, so each user only receives
--    changes to rows they are allowed to see.
-- ------------------------------------------------------------
DO $$
DECLARE t TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        FOREACH t IN ARRAY ARRAY['appointments', 'prescriptions', 'lab_tests', 'vital_records', 'bills',
                                 'notifications', 'staff', 'departments', 'inventory_items', 'beds'] LOOP
            IF to_regclass('public.' || t) IS NOT NULL
               AND NOT EXISTS (SELECT 1 FROM pg_publication_tables
                               WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = t) THEN
                EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
            END IF;
        END LOOP;
    END IF;
END $$;

COMMIT;
