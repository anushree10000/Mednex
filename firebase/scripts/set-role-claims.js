// MedNex – give every existing Firebase user the role: "authenticated" claim.
//
// The blocking functions only affect new sign-ups and sign-ins, so run this
// once for accounts that already exist. It also works on its own (no Blaze
// plan needed): just re-run it after new users register.
//
// Usage (from the firebase/ folder):
//   npm install firebase-admin
//   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
//   node scripts/set-role-claims.js
//
// Get the service-account JSON from Firebase console → Project settings →
// Service accounts → Generate new private key. Never commit that file.

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

async function main() {
  const auth = getAuth();
  let pageToken;
  let updated = 0;

  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) {
      const claims = user.customClaims || {};
      if (claims.role !== "authenticated") {
        // Keep any existing claims and add the role
        await auth.setCustomUserClaims(user.uid, { ...claims, role: "authenticated" });
        updated += 1;
        console.log(`Added role claim: ${user.email || user.uid}`);
      }
    }
    pageToken = page.pageToken;
  } while (pageToken);

  console.log(`Done. ${updated} user(s) updated. They pick up the claim at their next sign-in or token refresh.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
