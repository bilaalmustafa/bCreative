# BCreative EMS

Flutter employee-management application using GetX, Firebase Authentication,
Cloud Firestore, and Firebase Storage.

## Implemented modules

- Firebase login, reset-password flow, and role-protected navigation
- Super Admin employee directory with live totals, search, department/status/
  employment-type filters, pagination, Firebase Auth account provisioning,
  direct Firestore create, edit, deactivate, and reactivate
- Optional employee JPG/PNG profile photos stored securely in Firebase Storage
- Employee self-service contact profile, task updates, and file management
- Typed JSON models and Firestore repositories for employee profiles, tasks,
  task updates, and employee document metadata
- Live Firestore employee, department, task, and recent-activity dashboard data
- Reference-style Super Admin dashboard with responsive desktop/tablet/mobile
  layouts
- Responsive attendance management: live admin calendar, filters, attendance
  register, employee details, CSV export, and an employee self-service daily
  check-in/check-out flow

Leave, payroll, projects, reports, and settings are not yet backed by their own
modules. Their dashboard cards and shortcuts are visibly marked **Demo** (or
show **Coming soon**) so no sample value is presented as live Firestore data.

## Data and security design

The application has exactly two roles: `super_admin` and `employee`.

- Employee records, profile updates, task updates, document metadata, and
  dashboard reads use direct Cloud Firestore repositories and typed Dart
  `toJson()` / `fromJson()` models.
- Cloud Functions are not used. The Super Admin creates the employee's
  Email/Password Firebase Auth account in a secondary Firebase app, so the
  admin session stays signed in. The Auth UID is also the employee record ID.
  The temporary password is sent only to Firebase Auth and is never saved in
  Firestore.
- Since client apps cannot set Firebase custom claims, provisioned employee
  roles are read from a protected `users/{uid}` Firestore document. Existing
  Super Admin accounts continue to use their `super_admin` custom claim.
- Firestore and Storage rules default to deny. Employees can only access their
  own allowed profile, attendance, and document data; payroll and other
  unimplemented collections remain inaccessible. Attendance uses one fixed
  document per employee per day, so an employee cannot create a second
  check-in or change the original check-in after checking out.

## Notifications

The app includes a real-time in-app notification inbox on Web and mobile. An
employee receives task assignments, project assignments, and paid-payroll
alerts. Super Admins receive employee task activity, task-progress, check-in,
and check-out alerts. These use Firestore snapshot streams while the app is
open; operating-system background push notifications require a separate Firebase
Cloud Messaging setup.

## Setup

1. Enable Email/Password Authentication, Firestore, and Storage for the
   `bcreativeems` Firebase project.
2. Install Flutter packages with `flutter pub get`.
3. Deploy the configured rules, indexes, and storage rules:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

   For Flutter Web avatars, also apply the bucket CORS rule once. This only
   permits browser `GET` requests for an already-authorised download URL; it
   does not make Storage objects public or change the Storage rules.

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path 'service-account.json')
   node scripts/configure-storage-cors.mjs
   ```

4. Create the first Super Admin with the Admin SDK helper in
   `scripts/create-super-admin.mjs`. Its custom claims must include:

   ```json
   { "role": "super_admin" }
   ```

The employee creation form provisions the Auth login and the matching EMS
records together. Give the temporary password to the employee using a secure
channel and have them use **Forgot password** to choose their own password.

## Run

```bash
flutter run -d chrome
```
