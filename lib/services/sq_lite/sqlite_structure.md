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
│   └── report_table.dart            # Lab tests, medical reports & AI analysis data
└── services/                        # Typed domain CRUD services
    ├── user_db_service.dart         # Offline login, profile CRUD & active user session management
    ├── health_db_service.dart       # HealthData, Pregnancy & Cycle History operations
    ├── prescription_db_service.dart # Prescription & Medicine schedule operations
    └── report_db_service.dart       # Medical report & AI analysis operations
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
| **`FamilyRequestsTable`** | `family_requests` | Family invitations & join requests | `id`, `userId`, `familyId`, `expiresAt`, `status` |
| **`FamilyMembersTable`** | `family_members` | Family members & access controls | `id`, `userid`, `familyid`, `relation`, `access_level` (JSON) |
| **`HealthDataTable`** | `health_data` | Mother's core health profile & pregnancy status | `id` (UUID), `UserID`, `height`, `weight`, `bloodGroup`, `allergies` (JSON), `medicalConditions` (JSON), `rch_id`, `pregnancyStatus` |
| **`CycleHistories`** | `cycle_histories` | Menstrual cycle tracking logs | `id`, `health_id`, `cycleStartDate`, `cycleEndDate`, `cycleType` |
| **`Pregnancies`** | `pregnancies` | ANC records, risk status, obstetric codes & delivery details | `id` (UUID), `health_id`, `lmpDate`, `edDate`, `status`, `riskStatus`, `highestRiskStatus`, `flagged_complications` (JSON), `gravidity`, `parity` |
| **`Prescriptions`** | `prescriptions` | Doctor prescriptions & image attachments | `id` (UUID), `health_id`, `description`, `imageUrl`, `drive_file_id` |
| **`PrescriptionMedicines`** | `prescription_medicines` | Individual medicines & reminder configs | `id` (UUID), `prescriptionId`, `medicineName`, `dosage`, `timings` (JSON), `durationDays`, `reminder_config` (JSON) |
| **`PrescriptionMedicineTimings`** | `prescription_medicine_timings` | Intake history per dose | `id` (UUID), `prescriptionMedicineId`, `dateTime`, `medicineTakenTime`, `status` |
| **`Reports`** | `reports` | Lab reports & Gemini AI analysis details | `id` (UUID), `report_type`, `detail` (JSON), `healthDataID`, `imageUrl`, `description`, `saved`, `synced` |

---

## Offline Synchronization Standard

1. **`synced` Column (`INTEGER`)**: Every data table includes a `synced` column:
   - `0`: Newly created or updated offline (pending sync with `allomom_api`).
   - `1`: Successfully synced with the backend PostgreSQL database.
2. **Conflict-Free IDs**: UUID strings are generated locally for offline record creation (`Uuid().v4()`), enabling seamless upserts on the remote server.
3. **Database Indexes**: Performance indexes on foreign keys (`user_id`, `health_id`, `healthDataID`) and search fields (`phone`, `user_name`) are created in `AppMigrations.beforeOpen`.
