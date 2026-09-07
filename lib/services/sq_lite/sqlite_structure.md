# Allomom SQLite Local Storage Architecture (Drift ORM)

This document outlines the architectural patterns and conventions established for the SQLite local persistence layer in **Allomom**, modeled directly after the **`alloconnect-application`** standard.

---

## Directory Structure

```
lib/services/sq_lite/
├── drift_database.dart              # Root @DriftDatabase class wiring tables, native connection & migrations
├── drift_database.g.dart            # GENERATED: Drift companion classes, Data classes, DAOs & query engine
├── sqlite_service.dart              # Singleton SqLiteService for DB lifecycle (init, close, clear)
├── migrations/
│   └── app_migrations.dart          # Versioned migration strategy (onCreate, onUpgrade, beforeOpen indexes)
├── tables/                          # Individual table definitions
│   ├── initial_setup_table.dart     # Key-value config & active session tracking
│   ├── user_table.dart              # User profile, credentials & status
│   ├── user_entity_table.dart       # User to Entity mapping
│   ├── user_relation_table.dart     # User relationships
│   ├── family_table.dart            # Family units & details
│   ├── family_requests_table.dart   # Family join/request invites
│   ├── family_members_table.dart    # Family membership & access levels
│   ├── health_data_table.dart       # Physical vitals, cycles, pregnancy status
│   ├── cycle_history_table.dart     # Menstrual cycle tracking logs
│   ├── pregnancy_table.dart         # Pregnancy, ANC, risk classification & delivery records
│   ├── prescription_table.dart      # Prescriptions & attachment metadata
│   ├── prescription_medicine_table.dart # Prescribed medicines, dosage, schedule & reminder configs
│   ├── prescription_medicine_timing_table.dart # Logged medicine doses & intake status
│   ├── report_table.dart            # Lab tests, medical reports & AI analysis data
│   ├── vitals_table.dart            # Point-in-time vital readings
│   ├── pregnancy_anc_schedule_table.dart # Antenatal care visit schedule per pregnancy
│   ├── vaccination_table.dart       # Maternal & child vaccine schedule/records
│   ├── report_checklist_table.dart  # Lab/ultrasound reports that are still due
│   ├── report_attachment_table.dart # Files belonging to a report (local + cloud copy)
│   └── reminder_table.dart          # User-configured custom health reminders
└── services/                        # Typed domain CRUD services
    ├── user_db_service.dart         # User rows + active-session tracking
    ├── health_db_service.dart       # HealthData, Pregnancy & Cycle History operations
    ├── prescription_db_service.dart # Prescriptions, medicines & per-dose intake log
    ├── report_db_service.dart       # Medical report, AI analysis data & summaries
    ├── vitals_sqlite_service.dart   # Vital reading operations
    ├── family_db_service.dart       # Families, members, invite codes & join requests
    ├── reminder_db_service.dart     # Custom reminder operations
    └── pregnancy_care_db_service.dart # ANC visits, vaccinations, checklists & attachments
```

---

## Tables Overview & Column Specifications

| Table | SQL Table Name | Description | Key Fields |
| :--- | :--- | :--- | :--- |
| **`InitialSetup`** | `initial_setup` | Key-value store for app configuration & active session | `id`, `key`, `value` |
| **`Users`** | `users` | User profile, authentication, contact & role data | `id` (UUID), `name`, `email`, `phone`, `gender`, `dob`, `adline1`, `city`, `pincode`, `active`, `healthDataID`, `synced` |
| **`UserEntities`** | `user_entities` | Organization / entity association | `id`, `user_id`, `entity_id`, `type`, `leftAt`, `createdAt` |
| **`UserRelations`** | `user_relations` | Inter-user relations (Mother, Father, Child, Guardian) | `id`, `user_id`, `related_user_id`, `relation_type`, `createdAt` |
| **`Families`** | `families` | Family unit metadata & media | `id` (UUID), `name`, `code`, `motherId`, `fatherId`, `profileImage`, `bannerImage` |
| **`FamilyRequestsTable`** | `family_requests_table` | Family invitations & join requests | `id`, `userId`, `familyId`, `expiresAt`, `status` |
| **`FamilyMembersTable`** | `family_members_table` | Family members & access controls | `id`, `userid`, `familyid`, `relation`, `access_level` (JSON) |
| **`HealthDataTable`** | `health_data` | Mother's core health profile & pregnancy status | `id` (UUID), `UserID`, `height`, `weight`, `bloodGroup`, `allergies` (JSON), `medicalConditions` (JSON), `rch_id`, `pregnancyStatus` |
| **`CycleHistories`** | `cycle_histories` | Menstrual cycle tracking logs | `id`, `health_id`, `cycleStartDate`, `cycleEndDate`, `cycleType` |
| **`Pregnancies`** | `pregnancies` | ANC records, risk status, obstetric codes & delivery details | `id` (UUID), `health_id`, `lmpDate`, `edDate`, `status`, `riskStatus`, `highestRiskStatus`, `flagged_complications` (JSON), `gravidity`, `parity` |
| **`Prescriptions`** | `prescriptions` | Doctor prescriptions & image attachments | `id` (UUID), `health_id`, `description`, `imageUrl`, `drive_file_id` |
| **`PrescriptionMedicines`** | `prescription_medicines` | Individual medicines & reminder configs | `id` (UUID), `prescriptionId`, `medicineName`, `dosage`, `timings` (JSON), `durationDays`, `reminder_config` (JSON) |
| **`PrescriptionMedicineTimings`** | `prescription_medicine_timings` | Intake history per dose | `id` (UUID), `prescriptionMedicineId`, `dateTime`, `medicineTakenTime`, `status` |
| **`Reports`** | `reports` | Lab reports & Gemini AI analysis details | `id` (UUID), `report_type`, `detail` (JSON), `healthDataID`, `imageUrl`, `description`, `saved`, `synced` |
| **`Vitals`** | `vitals` | Point-in-time vital readings | `id` (UUID), `vital_key`, `value`, `unit`, `created_at`, `user_id`, `synced` |
| **`PregnancyAncSchedule`** | `pregnancy_anc_schedule` | Antenatal care visits for a pregnancy | `id` (UUID), `pregnancy_id`, `visit_number`, `trimester`, `scheduled_date`, `actual_date`, `status`, `weight_kg`, `bp`, `fundal_height_cm`, `fetal_heart_rate`, `synced` |
| **`Vaccinations`** | `vaccinations` | Vaccine schedule & administration records | `id` (UUID), `user_id`, `pregnancy_id` (nullable), `vaccine_name`, `dose_number`, `scheduled_date`, `administered_date`, `status`, `batch_number`, `administered_by`, `synced` |
| **`ReportChecklists`** | `report_checklists` | Lab tests / scans still due | `id` (UUID), `user_id`, `pregnancy_id` (nullable), `report_name`, `category`, `due_date`, `completed_date`, `status`, `file_path`, `result_summary`, `synced` |
| **`ReportAttachments`** | `report_attachments` | Files belonging to a report | `id` (UUID), `report_id`, `local_path`, `cloud_url` (nullable until uploaded), `file_name`, `mime_type`, `file_size_bytes`, `synced` |
| **`Reminders`** | `reminders` | User-configured custom health reminders | `id` (UUID), `user_id`, `title`, `reminder_type`, `frequency`, `hour`, `minute`, `channels` (JSON), `enabled`, `configurable`, `start_date`, `end_date`, `synced` |

---

## Local-Only Mode (current)

AlloMom runs entirely on this local database. `allomom-api` is called for
**authentication only**:

| Flow | Endpoint | Where |
| :--- | :--- | :--- |
| Send / verify OTP | `OtpApi.sendOtp`, `OtpApi.verifyOtp` | `contact_number_page.dart`, `verify_otp_page.dart` |
| Google sign-in | `AuthApi.authGoogle` | `contact_number_page.dart` |
| Registration | `AuthApi.registerMother` | `family_details_page.dart`, `kids_details_page.dart` |
| Seed profile right after login | `AuthApi.getMe` | `UserSessionManager.fetchUser()` |
| Sign out | `AuthApi.logout` | `UserSessionManager.logout()` |

Everything else — profile edits, pregnancies, ANC/vaccination/checklist
schedules, prescriptions and their doses, reports and attachments, family
members, reminders and vitals — reads and writes SQLite only, and every write
leaves `synced = 0`. No row is ever flipped to `1` today.

`HealthVitalSyncService` is a deliberate stub: its periodic timer and the
`VitalsApi.syncDataBulk` upload were removed, and it now only reports how many
rows are queued. When the sync implementation lands, that is the place to push
`synced = 0` rows and call the `unsynced*()` helpers each domain service
exposes (`unsyncedPrescriptions`, `unsyncedReports`, `unsyncedFamilies`,
`unsyncedReminders`, `unsyncedPregnancies`, …).

## Offline Synchronization Standard

1. **`synced` Column (`INTEGER`)**: Every data table includes a `synced` column:
   - `0`: Newly created or updated offline (pending sync with `allomom_api`).
   - `1`: Successfully synced with the backend PostgreSQL database.
2. **Conflict-Free IDs**: UUID strings are generated locally for offline record creation (`Uuid().v4()`), enabling seamless upserts on the remote server.
3. **Database Indexes**: Performance indexes on foreign keys (`user_id`, `health_id`, `healthDataID`) and search fields (`phone`, `user_name`) are created in `AppMigrations.beforeOpen`.

---

## Pregnancy Care Relationships

```
Users (1) ── (N) Pregnancies
Pregnancies (1) ── (N) PregnancyAncSchedule
Users (1) ── (N) Vaccinations       [pregnancy_id nullable]
Pregnancies (1) ── (N) Vaccinations [set = maternal vaccine, null = general/child]
Users (1) ── (N) ReportChecklists   [pregnancy_id nullable]
Reports (1) ── (N) ReportAttachments
```

`ReportChecklists` tracks that a test/report is **due**; `Reports` holds the
actual content once it exists, and `ReportAttachments` holds its files.

Foreign keys are plain UUID `TEXT` columns and are **not** enforced by SQLite
here, matching the rest of this schema. `PregnancyCareDbService.deleteAllForPregnancy`
clears child rows explicitly so deleting a pregnancy cannot orphan them.

## Tests

- `test/pregnancy_care_tables_test.dart` — schema + CRUD for the v3 care tables.
- `test/local_only_db_services_test.dart` — the domain services that replaced
  the API calls (reminders, family, prescriptions + timings, reports,
  pregnancy), each asserting rows land at `synced = 0`.

Both drive an in-memory database. `SqLiteService.overrideDatabaseForTesting`
points the singleton at it so the domain services can be exercised directly.

A debug-only CRUD harness for these tables lives at
`lib/features/pregnancy/test_pregnancy_page.dart`, reachable from
Settings → Developer → "Test Pregnancy · Local DB" in debug builds.
