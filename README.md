# MedNex

An iOS hospital-management app for 8 roles (patient, doctor, nurse, lab technician, pharmacist, admin, receptionist, accountant), built during the Apple & Infosys Development Program.

## Tech stack

- SwiftUI (iOS 26.2+), MVVM with protocol-based services
- Supabase (PostgreSQL, row-level security, Realtime) for hospital data, with Firebase logins trusted through Supabase third-party auth (see [SECURITY_SETUP.md](SECURITY_SETUP.md))
- Firebase Auth for login, plus email OTP and Face ID
- Stripe PaymentSheet (test mode) for bill payments
- App Intents / Siri Shortcuts

## Project layout

| Path | What's in it |
| --- | --- |
| `MedNex.xcodeproj` | Xcode project. Open this file to build and run |
| `MedNex/App` | App state, Siri intents and shortcuts |
| `MedNex/Core` | Onboarding, authentication, role-based navigation |
| `MedNex/Features` | One folder per role: Admin, Doctor, Nurse, LabTech, Patient, Pharmacist |
| `MedNex/Shared` | Models, services (Supabase, Firebase, Stripe, cache, security), components, design system |
| `MednexTests` | XCTest unit tests, run with `./run_tests.sh` |
| `*.sql` | Supabase schema, migrations, RLS policies and seed data. `schema_migration_v6_security_realtime.sql` switches on role-based security |
| `firebase/` | Firebase functions and a script that add the token claim Supabase needs |

## Run it

1. Open `MedNex.xcodeproj` in Xcode (not the `MedNex` folder).
2. Wait for Swift packages to resolve (Firebase, Supabase, Stripe).
3. Choose an iPhone simulator and press Run.

Signing on a real device needs your own team and bundle identifier under Signing & Capabilities.
