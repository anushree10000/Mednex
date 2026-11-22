// MedNex – Firebase blocking functions for Supabase third-party auth.
//
// Supabase picks the Postgres role from the "role" claim in the JWT.
// Firebase ID tokens don't include it, so without this every request would
// run as "anon" and row-level security would block it.
//
// These functions add role: "authenticated" when a user signs up or signs in.
// Requires Firebase Authentication with Identity Platform (Blaze plan).
// Deploy from the firebase/ folder:  firebase deploy --only functions

const { beforeUserCreated, beforeUserSignedIn } = require("firebase-functions/v2/identity");

exports.supabaseRoleOnCreate = beforeUserCreated(() => ({
  customClaims: { role: "authenticated" },
}));

exports.supabaseRoleOnSignIn = beforeUserSignedIn(() => ({
  customClaims: { role: "authenticated" },
}));
