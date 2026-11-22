# Security and live updates: setup

This turns on real role-based security in the database and live updates in the app.

**What changes**

- **Before:** row-level security (RLS) was switched off and the public key could read and change every table. The app also never told Supabase who the user was, so the database couldn't check anything.
- **After:**
  - The app sends the user's Firebase login token with every request.
  - Supabase trusts tokens from this Firebase project only.
  - RLS policies decide what each role can see and change. Patients only see their own records, staff work on hospital data, and only admins manage users and staff.
  - Screens refresh automatically when another user changes data the current user can see.

**Do the steps in this order.**
- **Do step 1 before running the updated app.** The app now sends Firebase tokens, and Supabase rejects them until it's told to trust this Firebase project.
- **Step 5 switches security on.** If it runs before steps 1–3, the app is blocked until they're done.

| Step | Where | What |
| --- | --- | --- |
| 1 | Supabase dashboard | Trust Firebase logins |
| 2 | Firebase | Add the `role: authenticated` claim to tokens |
| 3 | Your Mac | Give existing users the claim |
| 4 | Xcode | Run the updated app, then sign out and sign back in |
| 5 | Supabase SQL editor | Run `schema_migration_v6_security_realtime.sql` |
| 6 | App | Check it works |

## 1. Trust Firebase logins in Supabase

1. In the Supabase dashboard, open **Authentication** settings, find the **Third-Party Auth** section, and add a **Firebase** integration.
2. Enter the Firebase project ID: `mednex-56348`.

## 2. Add the role claim to Firebase tokens

Supabase uses the `role` claim in the token to decide which database role a request runs as. Firebase tokens don't include it, so without it every request would be treated as anonymous.

**Option A (automatic, needs the Blaze plan and Identity Platform):**

1. In the Firebase console, open **Authentication → Settings** and upgrade to **Firebase Authentication with Identity Platform**.
2. From the `firebase/` folder, deploy the blocking functions:

```bash
cd firebase/functions && npm install && cd ..
firebase deploy --only functions --project mednex-56348
```

Every new sign-up and sign-in then gets the claim automatically.

**Option B (free, manual):** skip the functions and use the script in step 3. You need to re-run it whenever someone new registers.

## 3. Give existing users the claim

1. In the Firebase console, open **Project settings → Service accounts → Generate new private key**. Save the file outside the repo, and never commit it.
2. Run the script:

```bash
cd firebase
npm install firebase-admin
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
node scripts/set-role-claims.js
```

## 4. Run the updated app

Build and run from Xcode. Then sign out and sign back in on each test account, so the device gets a fresh token that carries the new claim.

The app already works at this point. Security is still off; the requests just carry the token now.

## 5. Switch security on

In the Supabase dashboard, open **SQL Editor**, paste the contents of `schema_migration_v6_security_realtime.sql`, and run it.

It's safe to run more than once. It also:

- removes the old development policies and the "public key can do everything" grants;
- adds an `audit_logs` table;
- adds a `staff_email_for_id` function, so staff-ID login still works without exposing the staff table;
- makes sure the tables the app listens to are published for Realtime.

Also check that Realtime is enabled for the project under **Database → Publications → supabase_realtime**.

## 6. Check it works

- **Patient** (`demo@mednex.com`): sees only their own appointments, prescriptions and bills.
- **Doctor** (`dr.smith@mednex.com`): sees all appointments and can write a prescription.
- **Live updates:** keep the patient logged in on one simulator, and write a prescription as the doctor on another. It appears on the patient's screen within about a second.
- **Staff ID login** (e.g. `DOC001`) still works.

## Rules after the change

| Who | Can do |
| --- | --- |
| Not signed in | Nothing, except the staff-ID-to-email lookup used by the login screen |
| Patient | Read their own appointments, prescriptions, lab tests, vitals, bills, admissions, notifications and chats. Book or cancel their own appointments, request lab tests, pay their own bills, edit their own health details. Read the doctor and department directory. |
| Staff (doctor, nurse, lab tech, pharmacist, receptionist, accountant) | Read and update hospital data (appointments, prescriptions, labs, vitals, bills, beds, inventory, shifts). Read the staff list. Cannot read private patient chats. |
| Admin | Everything staff can do, plus manage users, roles, staff, departments and doctors, and read audit logs |
| Everyone | Cannot change their own role. Tokens from any other Firebase project are rejected. |

### Staff accounts now need an admin

Anyone could previously sign up as "admin" from the registration screen. Now a new account can only be created as a **patient**, unless an admin has already given that email a staff role. To make someone staff, an admin changes their role. In the SQL editor:

```sql
UPDATE users SET role = 'nurse' WHERE email = 'new.nurse@mednex.com';
```

The demo-account seeder (`SeedDataService`) creates staff accounts directly, so run it before step 5, or have an admin assign the roles afterwards.

## If something goes wrong

To get back to the old development setup (no security), run `disable_rls.sql` and then `supabase_permissions.sql` in the SQL editor.

## Known limits (next steps)

- Every staff role can update every hospital table. Per-role rules would be stricter, e.g. only pharmacists dispense, and only lab techs enter results.
- Saves still happen in the background. If one fails (for example, because a policy blocks it), the error is only logged and the screen isn't rolled back.
- A patient can edit any column of their own appointment row, not only its status.

## Tested

The migration was run on PostgreSQL 16 against the repo's schema and migrations, with Supabase's `anon` and `authenticated` roles and JWT claims simulated. All 35 access checks passed, covering anonymous access, patient isolation, sign-up role rules, doctor and admin permissions, and rejection of tokens from other Firebase projects. Running it a second time also succeeded. The Swift changes still need a build in Xcode, and the live updates need a test on two devices.
