/**
 * Adds the browser-read CORS rule needed for Firebase Storage download URLs.
 *
 * Usage (PowerShell):
 *   $env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path 'service-account.json')
 *   node scripts/configure-storage-cors.mjs
 */

import { readFile } from 'node:fs/promises';
import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';

const bucketName = 'bcreativeems.firebasestorage.app';
const corsConfigUrl = new URL('../firebase/storage.cors.json', import.meta.url);
const [avatarReadRule] = JSON.parse(await readFile(corsConfigUrl, 'utf8'));

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  throw new Error(
    'Set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON file first.',
  );
}

if (!getApps().length) {
  initializeApp({
    credential: applicationDefault(),
    storageBucket: bucketName,
  });
}

const bucket = getStorage().bucket();
const [metadata] = await bucket.getMetadata();
const existingRules = metadata.cors ?? [];
const ruleAlreadyExists = existingRules.some(
  (rule) =>
    JSON.stringify(rule.origin ?? []) === JSON.stringify(avatarReadRule.origin) &&
    JSON.stringify(rule.method ?? []) === JSON.stringify(avatarReadRule.method),
);

if (!ruleAlreadyExists) {
  await bucket.setCorsConfiguration([...existingRules, avatarReadRule]);
}

console.log(
  ruleAlreadyExists
    ? `CORS avatar-read rule is already configured for ${bucketName}.`
    : `CORS avatar-read rule configured for ${bucketName}.`,
);
