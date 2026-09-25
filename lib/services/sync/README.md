# Offline-first data layer

The app reads from SQLite, never straight from the network. Every screen works
offline; `SyncService` reconciles with allomom-api-new in the background.

```
screens ──read──> drift (sqlite) <──reconcile──> SyncService ──HTTP──> API
   │                   ▲
   └──write────────────┘  (synced = 0, pushed on the next pass)
```

## Local schema

The tables in `lib/services/sq_lite/tables/` that mirror the server match it
column for column, plus two of their own:

- `synced` — 0 while the row holds a local edit the server has not seen
- `synced_at` — the server `updated_at` this row was last reconciled at

`sync_state` holds one watermark per module. Those values are always what the
**server** returned, never a device clock reading: a phone with a wrong clock
would otherwise ask for changes since a moment that never happened and skip a
window of updates permanently.

App-local tables (`cycle_histories`, `prescriptions`, `reports`, `reminders`,
`families`, …) have no server counterpart yet and sync leaves them alone.

## The loop

1. **Sign in** → `GET /me/profile/get_all` seeds the local database and sets
   every module's watermark to the bundle's `server_time`.
2. **Every 5 minutes, and on demand** → for each module in dependency order:
   push the rows where `synced = 0`, apply what comes back, store the new
   watermark.
3. **Writes** land in SQLite first with `synced = 0`, then attempt the network.
   A failed request changes nothing — the edit is on screen and still queued.

Module order matters and is fixed in `kSyncMappers`: a pregnancy must be written
before the ANC rows that point at it.

## Conflicts

Last-write-wins on `updated_at`. When a local edit loses, the server's version
arrives in the same response and overwrites it — the local row is not left
dirty, because there is nothing left to push.

## Adding a module

Add a `SyncMapper` in `sync_mappers.dart` and list it in `kSyncMappers`. The
engine is generic over the mapper and names no table. The two directions are
deliberately asymmetric: `applyServerRow` writes every column the server sent,
while `toServerJson` sends only the fields the API marks writable — ids, server
timestamps and owner keys are the server's to set.

## Controllers

| | |
| --- | --- |
| `MainController` | The user and health record; the derived state screens read (`isPregnant`, `currentGestationalWeek`, `cyclePrediction`, …), each delegating to the controller that owns it. |
| `AuthController` | OTP sign-in, token lifetime, sign-out. |
| `PregnancyController` | The active pregnancy and its three schedules. |
| `BabyController` | Babies, their immunizations and milestones. |
| `VitalsController` | The vitals stream — every measurement, with its history. |

The care schedules are generated only by the server — seeding a second set
locally would duplicate the whole calendar. Creating a baby therefore needs the
network. Creating a pregnancy does not: offline, `PregnancyController` saves the
bare pregnancy row with a client UUID and `synced = 0`; when `/sync/pregnancy`
inserts it, the server seeds its ANC, vaccination and report rows (the module's
`on_insert` hook), and the `anc` / `pregnancy_vaccination` / `report_checklist`
passes that follow pull them down. `ConnectionController` runs a sync as soon as
the connection comes back.

## Tokens

`SecureTokenStore` keeps the access and refresh tokens in the Keychain
(iOS) / EncryptedSharedPreferences-backed Keystore (Android) — not
SharedPreferences, since a refresh token is a year-long bearer credential that
plain preferences expose on a rooted device.

`ApiBase` retries a 401 once after refreshing, so no screen has to think about
an access token ageing out. If the refresh itself is rejected, the session is
cleared and the app returns to sign-in.

## Where measurements live

Height, weight, blood group, blood pressure and cycle length are readings in
`vitals_stream`, not fields on the health profile, so they keep a history rather
than being overwritten. That includes the cycle: `VitalKeys.periodStart` drives
the predictions, which is why the health record carries only the LMP.

Schedule status (`pending` / `done` / `missed`) is **derived**, never stored —
see `schedule_status.dart`. A visit is done exactly when it has a completion
date and missed exactly when its window closed without one. A stored status
would be a third fact that can disagree with those two, and it would go stale on
its own, since nothing writes to a row as it ages past its due date.
