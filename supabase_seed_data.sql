-- ============================================================
-- MedNex Supabase Seed Data
-- Run this AFTER supabase_schema.sql and supabase_permissions.sql
-- 
-- Note: User IDs here are placeholders. The SeedDataService in the
-- app will create the actual Firebase users and sync profiles.
-- This script seeds supporting data: departments, inventory,
-- sample appointments, prescriptions, lab tests, etc.
-- ============================================================

-- ============================================================
-- 1. DEPARTMENTS
-- Columns: id, name, head_doctor_id, head_doctor_name, staff_count,
--          location, description, is_active, created_at
-- ============================================================
INSERT INTO departments (id, name, description, location, staff_count, is_active)
VALUES
    ('dept1', 'General Medicine', 'Primary care and internal medicine', 'Floor 1, Wing A', 8, true),
    ('dept2', 'Cardiology', 'Heart and cardiovascular care', 'Floor 2, Wing B', 5, true),
    ('dept3', 'Pediatrics', 'Child and adolescent medicine', 'Floor 1, Wing C', 6, true),
    ('dept4', 'Orthopedics', 'Bone, joint, and muscle care', 'Floor 3, Wing A', 4, true),
    ('dept5', 'Dermatology', 'Skin, hair, and nail care', 'Floor 2, Wing A', 3, true),
    ('dept6', 'Neurology', 'Brain and nervous system', 'Floor 3, Wing B', 4, true),
    ('dept7', 'Pathology', 'Laboratory testing and diagnostics', 'Basement 1', 5, true),
    ('dept8', 'Pharmacy', 'Medicine dispensing and counseling', 'Ground Floor', 4, true),
    ('dept9', 'Emergency', '24/7 emergency care', 'Ground Floor, Wing D', 10, true),
    ('dept10', 'Administration', 'Hospital administration', 'Floor 4', 6, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. INVENTORY ITEMS
-- Columns: id, name, category, stock, reorder_level, unit_price,
--          supplier, last_updated
-- ============================================================
INSERT INTO inventory_items (id, name, category, stock, reorder_level, unit_price, supplier)
VALUES
    ('inv1', 'Paracetamol 500mg', 'Medication', 500, 100, 2.50, 'PharmaCorp India'),
    ('inv2', 'Amoxicillin 250mg', 'Medication', 350, 80, 8.00, 'MediPharma Ltd'),
    ('inv3', 'Surgical Gloves (L)', 'Consumable', 2000, 500, 15.00, 'SafeHands Pvt Ltd'),
    ('inv4', 'N95 Masks', 'Consumable', 1500, 300, 25.00, 'BreatheEasy Co'),
    ('inv5', 'IV Saline 500ml', 'Consumable', 200, 50, 45.00, 'AquaMed Solutions'),
    ('inv6', 'Omeprazole 20mg', 'Medication', 400, 100, 5.50, 'GastroPharm Ltd'),
    ('inv7', 'Digital Thermometer', 'Equipment', 50, 10, 350.00, 'MedEquip India'),
    ('inv8', 'Blood Glucose Strips', 'Consumable', 800, 200, 18.00, 'DiabeCheck Co'),
    ('inv9', 'Metformin 500mg', 'Medication', 600, 150, 4.00, 'DiabetaCare Pharma'),
    ('inv10', 'Syringes 5ml', 'Consumable', 3000, 500, 8.00, 'InjectSafe Ltd'),
    ('inv11', 'Azithromycin 500mg', 'Medication', 25, 80, 12.00, 'AntibioPharm Ltd'),
    ('inv12', 'Surgical Masks', 'Consumable', 150, 300, 10.00, 'SafeGuard Pvt Ltd'),
    ('inv13', 'Ibuprofen 400mg', 'Medication', 200, 100, 3.00, 'PainRelief Pharma'),
    ('inv14', 'Cetrizine 10mg', 'Medication', 450, 100, 2.00, 'AllergyFree Ltd'),
    ('inv15', 'Bandage Rolls', 'Consumable', 600, 100, 20.00, 'WoundCare India')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. BEDS
-- Columns: id, number, ward, floor, status, patient_name
-- ============================================================
INSERT INTO beds (id, number, ward, floor, status, patient_name)
VALUES
    ('bed-gwa-01', 'GWA-01', 'General Ward A', '1', 'available', NULL),
    ('bed-gwa-02', 'GWA-02', 'General Ward A', '1', 'occupied', 'Rahul Sharma'),
    ('bed-gwa-03', 'GWA-03', 'General Ward A', '1', 'available', NULL),
    ('bed-gwa-04', 'GWA-04', 'General Ward A', '1', 'occupied', 'Priya Mehta'),
    ('bed-gwb-01', 'GWB-01', 'General Ward B', '1', 'available', NULL),
    ('bed-gwb-02', 'GWB-02', 'General Ward B', '1', 'occupied', 'Amit Kumar'),
    ('bed-gwb-03', 'GWB-03', 'General Ward B', '1', 'maintenance', NULL),
    ('bed-icu-01', 'ICU-01', 'ICU', '2', 'occupied', 'Neha Tiwari'),
    ('bed-icu-02', 'ICU-02', 'ICU', '2', 'available', NULL),
    ('bed-icu-03', 'ICU-03', 'ICU', '2', 'occupied', 'Suresh Patel'),
    ('bed-icu-04', 'ICU-04', 'ICU', '2', 'reserved', NULL),
    ('bed-ped-01', 'PED-01', 'Pediatric', '1', 'available', NULL),
    ('bed-ped-02', 'PED-02', 'Pediatric', '1', 'occupied', 'Baby Arjun'),
    ('bed-mat-01', 'MAT-01', 'Maternity', '2', 'available', NULL),
    ('bed-mat-02', 'MAT-02', 'Maternity', '2', 'occupied', 'Anita Verma'),
    ('bed-sur-01', 'SUR-01', 'Surgical', '3', 'available', NULL),
    ('bed-sur-02', 'SUR-02', 'Surgical', '3', 'occupied', 'Rajesh Gupta')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. SHIFTS
-- Columns: id, staff_id, staff_name, date, start_time, end_time,
--          department, shift_type, notes
-- (date/start_time/end_time are TIMESTAMPTZ)
-- ============================================================
INSERT INTO shifts (id, staff_id, staff_name, date, start_time, end_time, shift_type, department)
VALUES
    ('shift1', 'DOC001', 'Dr. Sarah Smith', CURRENT_DATE, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '16:00', 'Morning', 'General Medicine'),
    ('shift2', 'NRS001', 'Emily Davis', CURRENT_DATE, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '16:00', 'Morning', 'Nursing'),
    ('shift3', 'LAB001', 'Michael Chen', CURRENT_DATE, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '17:00', 'Morning', 'Pathology'),
    ('shift4', 'PHR001', 'Lisa Rodriguez', CURRENT_DATE, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '17:00', 'Morning', 'Pharmacy'),
    ('shift5', 'DOC001', 'Dr. Sarah Smith', CURRENT_DATE + 1, CURRENT_DATE + 1 + TIME '08:00', CURRENT_DATE + 1 + TIME '16:00', 'Morning', 'General Medicine'),
    ('shift6', 'NRS001', 'Emily Davis', CURRENT_DATE + 1, CURRENT_DATE + 1 + TIME '16:00', CURRENT_DATE + 2 + TIME '00:00', 'Evening', 'Nursing'),
    ('shift7', 'LAB001', 'Michael Chen', CURRENT_DATE + 2, CURRENT_DATE + 2 + TIME '09:00', CURRENT_DATE + 2 + TIME '17:00', 'Morning', 'Pathology')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 5. TIME SLOTS for demo doctor (next 7 weekdays)
-- Columns: id, doctor_id, date, start_time, end_time, is_booked
-- (date/start_time/end_time are TIMESTAMPTZ)
-- ============================================================
DO $$
DECLARE
    d DATE;
    slot_start TIMESTAMPTZ;
    slot_end TIMESTAMPTZ;
    slot_id TEXT;
    doctor_id TEXT := 'DOC001';
BEGIN
    FOR i IN 0..6 LOOP
        d := CURRENT_DATE + i;
        -- Skip weekends
        IF EXTRACT(DOW FROM d) NOT IN (0, 6) THEN
            FOR h IN 9..16 LOOP
                slot_id := 'ts_' || TO_CHAR(d, 'YYYYMMDD') || '_' || LPAD(h::TEXT, 2, '0');
                slot_start := d + (h || ' hours')::INTERVAL;
                slot_end := d + (h || ' hours')::INTERVAL + INTERVAL '30 minutes';
                INSERT INTO time_slots (id, doctor_id, date, start_time, end_time, is_booked)
                VALUES (slot_id, doctor_id, d, slot_start, slot_end, false)
                ON CONFLICT (id) DO NOTHING;
            END LOOP;
        END IF;
    END LOOP;
END $$;

-- ============================================================
-- Done! Now run the app and it will create Firebase users and
-- sync profiles via SeedDataService.
-- ============================================================

SELECT 'Seed data inserted successfully!' AS status;
SELECT COUNT(*) AS departments FROM departments;
SELECT COUNT(*) AS inventory_items FROM inventory_items;
SELECT COUNT(*) AS beds FROM beds;
SELECT COUNT(*) AS shifts FROM shifts;
SELECT COUNT(*) AS time_slots FROM time_slots;
