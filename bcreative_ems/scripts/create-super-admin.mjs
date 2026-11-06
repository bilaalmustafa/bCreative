/**
 * One-time Super Admin provisioning (run locally, not from the Flutter app).
 *
 * Prerequisites:
 *   1. Firebase project with Email/Password auth enabled; disable public sign-up.
 *   2. Service account JSON path in GOOGLE_APPLICATION_CREDENTIALS.
 *   3. npm install firebase-admin in this scripts folder (or run from a small Node project).
 *
 * Usage:
 *   node create-super-admin.mjs admin@company.com 'StrongPasswordHere'
 */

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const email = process.argv[2];
const password = process.argv[3];

if (!email || !password) {
  console.error('Usage: node create-super-admin.mjs <email> <password>');
  process.exit(1);
}

if (!getApps().length) {
  initializeApp();
}

const auth = getAuth();
const user = await auth.createUser({ email, password, emailVerified: true });
await auth.setCustomUserClaims(user.uid, {
  role: 'super_admin',
});
console.log(`Super Admin created: ${user.uid} (${email})`);
