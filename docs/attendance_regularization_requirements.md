# Attendance Regularization — Backend Requirements & Data Model

**Status:** Draft for backend system design
**Owner:** Mobile (WowCare) → Backend
**Scope:** Adds a *regularization* workflow on top of the existing Staff Attendance / Overtime module (microservice `attendance-ms`).
**Audience:** Backend engineers designing the API + schema.

This document specifies the behavior the mobile app already implements on the client side (module `attendance_regularization`) and what the backend must provide to support it. It is written to sit **on top of the current attendance module** and reuse its records, not replace them.

---

## 1. Problem statement

Staff frequently **forget to sign out**. Today the system auto-closes the open session at the school's end time (a **soft / system sign-out**). That produces an attendance record with an artificial sign-out time, which silently corrupts worked-hours and overtime.

Regularization makes this explicit and correctable:

1. When a staff has an unresolved soft sign-out, the app **blocks their next sign-in** with a gate until they resolve yesterday.
2. The staff either **confirms** the system time or **requests a correction** (actual time + reason).
3. Until an **admin approves** the correction, that sign-out session (and any hours after the soft time) **is not counted** in attendance/overtime.
4. Admins **approve** requests (optionally **modifying** the time with a reason) — **there is no reject** — and can **bulk-approve** the whole queue.

> **Design rule (headline):** A `SYSTEM`-closed session with a pending regularization is **provisional** — excluded from finalized hours/overtime and flagged `needsAttention` — until it is confirmed or approved.

---

## 2. Scope

**In scope**
- Detecting soft/missed sign-outs and exposing them to the app (the "gate").
- A regularization request lifecycle (create → approve/modify → apply → recompute).
- Staff self-service list and admin approval inbox (single + bulk approve).
- Applying the approved correction back onto the attendance record and recomputing overtime.

**Out of scope (for v1, but data model should not preclude)**
- Missed **sign-in** and **full-day** corrections (enum reserved; flows can follow the same lifecycle).
- Auto-approval policies / SLAs / escalations.
- Web admin UI (this doc is API-first; web can consume the same endpoints).

---

## 3. Actors & roles

| Actor | Capabilities |
|---|---|
| **Staff** | See their own pending gate; confirm soft time; raise correction; list/cancel their own requests. |
| **Admin** (`ORGANIZATION_ADMIN` / school admin) | List pending requests for the school; approve (with optional modify + reason); bulk-approve. **Cannot reject.** |

Authorization reuses the existing `X-Organization-Code` / `X-School-Code` headers + auth interceptor. Staff endpoints are scoped to the authenticated staff; admin endpoints require an admin role for the school.

---

## 4. Core concepts / glossary

| Term | Meaning |
|---|---|
| **Soft sign-out** | An attendance session auto-closed by the system at school end time. On the record: `signedOutMethod = SYSTEM`. |
| **Gate** | The mandatory next-day pop-up that blocks sign-in until an unresolved soft sign-out is resolved. |
| **Confirm** | Staff accepts the system time as-is. No time change; resolves the gate. May not require admin approval (see §8.2). |
| **Correction (request)** | Staff proposes a different actual sign-out time + reason → creates a `PENDING` regularization needing admin approval. |
| **Apply** | On approval, write the final time onto the attendance record (`signedOutMethod = REGULARIZED`) and recompute the day. |
| **Provisional session** | A `SYSTEM`-closed session not yet confirmed/approved. Excluded from finalized hours. |

---

## 5. End-to-end flow

### 5.1 Staff — next-day gate (mandatory)
1. On app open / attempted sign-in, client calls **GET pending gate** for the staff.
2. If a soft sign-out is unresolved, the app shows a **single bottom sheet** (mandatory, non-dismissible) containing: the missed date, the system time, the "won't be counted until regularized" consequence, an editable **actual sign-out time** (pre-filled to the soft time), and a **reason** field.
3. Staff submits:
   - **Time unchanged** → *Confirm* (reason optional).
   - **Time changed** → *Correction request* (reason required).
4. Sign-in is only allowed once the gate is resolved (confirmed or a request exists — see §8.3 for the policy choice).

### 5.2 Staff — my regularizations
- A list of the staff's requests with status (`Pending`, `Approved`, `Cancelled`), the requested time, reason, and decision info.
- Optional "needs attention" banner if an unresolved gate exists.

### 5.3 Admin — approval inbox
- List of **pending** requests for the school (staff, type, date, requested change, reason).
- Tap a request → approve sheet: shows reason, editable time field(s), and a **"Reason for change"** note. Actions: **Approve** (optionally modified). No reject.
- **Approve all (N)** — bulk-approve every pending request *as submitted*, after a confirmation. Requests needing a manual time change should be opened individually first.

---

## 6. Request lifecycle (state machine)

```
                 confirm (no change)
   [soft sign-out] ───────────────► [RESOLVED/APPLIED]   (auto, see §8.2)
        │
        │ correction requested
        ▼
     [PENDING] ──approve──────────► [APPROVED] ──apply──► attendance updated + day recomputed
        │
        └──cancel (by staff)──────► [CANCELLED]
```

- **No `REJECTED` transition** — admins approve (with modification) rather than reject.
- `APPROVED` is terminal; the correction is applied atomically with the status change.
- `CANCELLED` is terminal; staff withdrew before a decision.
- Reserve `REJECTED` in the enum for forward compatibility / server-side automation, but the app never sets it.

---

## 7. Data model

### 7.1 New table: `staff_attendance_regularizations`

| Column | Type | Notes |
|---|---|---|
| `code` | string (PK) | e.g. `SREG_XXXX` |
| `organization_code` | string | FK org |
| `school_code` | string | FK school |
| `staff_code` | string | FK staff |
| `attendance_date` | date | The day being corrected (school-local calendar date) |
| `type` | enum | `MISSED_SIGN_OUT` \| `MISSED_SIGN_IN` \| `MISSED_FULL_DAY` \| `TIME_CORRECTION` |
| `target_record_code` | string, nullable | The `staff_attendance_records.code` being corrected (null for full-day/sign-in creation) |
| `classroom_code` | string, nullable | Context (room of the session) |
| `soft_sign_out_at` | timestamptz, nullable | System time being corrected (context/audit) |
| `requested_sign_in_at` | timestamptz, nullable | What the staff asked for |
| `requested_sign_out_at` | timestamptz, nullable | What the staff asked for |
| `reason` | text | Staff's reason |
| `status` | enum | `PENDING` \| `APPROVED` \| `CANCELLED` \| (`REJECTED` reserved) |
| `applied_sign_in_at` | timestamptz, nullable | Final value written on approval (may differ from requested if admin modified) |
| `applied_sign_out_at` | timestamptz, nullable | Final value written on approval |
| `decided_by_code` | string, nullable | Admin user code |
| `decided_by_name` | string, nullable | Denormalized for display |
| `decided_at` | timestamptz, nullable | |
| `decision_note` | text, nullable | Admin's "reason for change" |
| `method` | enum | `APP` \| `WEB` |
| `time_zone` | string | IANA zone used to interpret wall-clock inputs (see §10.1) |
| `created_by_code` | string | |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |
| `deleted_at` | timestamptz, nullable | Soft delete |

**Suggested indexes**
- `(school_code, status)` — admin inbox / bulk approve.
- `(staff_code, status)` — staff list + gate lookups.
- `(target_record_code)` — one active regularization per record (see §8.5).
- Partial unique: `(target_record_code) WHERE status = 'PENDING'` — prevent duplicate pending requests for the same session.

### 7.2 Changes to existing `staff_attendance_records`

The session record already carries `signedInTime`, `signedOutTime`, `signedInBy`, `signedOutBy`, `signedOutMethod`, `classroomCode`, `attendanceDate`, `code`. Add / formalize:

| Column | Type | Notes |
|---|---|---|
| `signed_out_method` | enum | Ensure values include `STAFF`, `SYSTEM`, `ADMIN`, `REGULARIZED`. `SYSTEM` = soft close. |
| `is_regularized` | bool, default false | True once a correction is applied. |
| `regularization_code` | string, nullable | Back-reference to the applied regularization. |
| `is_provisional` | bool (derived or stored) | True when `signed_out_method = SYSTEM` and an unresolved gate exists. Used by overtime calc to exclude. |

> Preferred: keep `is_provisional` **derived** (a session is provisional iff `signed_out_method = SYSTEM` AND no confirm/approval yet) to avoid drift. Store only if the calc needs it denormalized for performance.

### 7.3 Relationship to overtime records

`staff-overtime-records` (the `/profile` + `/calculate` endpoints) must honor the provisional rule (§8.1). No schema change required if the calculator reads `staff_attendance_records`; it must **skip/flag provisional sessions**.

---

## 8. Business rules

### 8.1 Provisional exclusion (core)
- While a session is **provisional** (`SYSTEM` sign-out, unresolved):
  - It is **excluded from finalized** `regularMinutes` / `overtimeMinutes` / `totalMinutes` for that day, **or** counted only up to a defined cutoff — **[DECISION NEEDED, see §12]**.
  - The day is returned with `needsAttention = true` in `/staff-overtime-records/profile`.
- On **confirm** or **approve**, the session becomes final and the day is recomputed via the existing `calculate` step.

### 8.2 Confirm vs. correction — does confirm need approval?
- **Confirm (time unchanged):** the staff accepts the system time. Recommended: **auto-resolve without admin approval** — set the session `signed_out_method = STAFF` (or a new `CONFIRMED`), mark non-provisional, recompute. Optionally still write an `APPROVED` regularization row for audit with `decided_by = SYSTEM`.
- **Correction (time changed):** always `PENDING` → requires admin approval. **[Confirm this policy, §12]**

### 8.3 Gate enforcement
- The gate is **mandatory before sign-in**: the sign-in endpoint should reject (or the client blocks) sign-in while an unresolved soft sign-out exists for that staff.
- Policy choice: does *raising a correction* (still `PENDING`) unblock sign-in, or must it be *confirmed/approved*? Recommended: **raising a request unblocks** sign-in (staff shouldn't be blocked waiting on an admin), while the prior day's hours stay provisional until approved. **[Confirm, §12]**

### 8.4 Applying an approval
On approve (single or bulk), atomically:
1. Set regularization `status = APPROVED`, `decided_by_*`, `decided_at`, `decision_note`, `applied_sign_out_at` (= admin-modified time if provided, else `requested_sign_out_at`).
2. Update the target `staff_attendance_records`: `signed_out_time = applied_sign_out_at`, `signed_out_method = REGULARIZED`, `is_regularized = true`, `regularization_code`.
3. Recompute overtime for `(staff_code, attendance_date)`.

### 8.5 Uniqueness / idempotency
- At most **one `PENDING`** regularization per `target_record_code` (partial unique index). A second create returns the existing one (idempotent) or `409`.
- Approve is idempotent: approving an already-`APPROVED` request is a no-op returning the current state.

### 8.6 Validation
- `requested_sign_out_at` must be **after** the session's `signed_in_time` and on the same attendance date (or within the school's overnight window).
- Correction requires a non-empty `reason`.
- Admin modify requires the modified time to pass the same validation; `decision_note` recommended when modifying.

### 8.7 Authorization
- Staff may only create/list/cancel **their own** requests.
- Only school **admins** may list-pending, approve, or bulk-approve, scoped to their school.

---

## 9. API surface

All under `attendance-ms`, base `/api/v1`. JSON, UTC ISO-8601 timestamps in payloads (with `timeZone` for interpretation). Auth + org/school headers as elsewhere.

### 9.1 Get pending gate (staff)
```
GET /staff-attendance-regularizations/pending-gate?staffCode={code}
```
Returns unresolved soft sign-outs blocking sign-in.
```json
{
  "success": true,
  "data": [
    {
      "recordCode": "SATT_...",
      "attendanceDate": "2026-06-23",
      "softSignOutAt": "2026-06-23T12:00:00Z",
      "signInAt": "2026-06-23T03:30:00Z",
      "classroomName": "Office"
    }
  ]
}
```

### 9.2 Create / resolve (staff)
```
POST /staff-attendance-regularizations
```
```json
{
  "staffCode": "STF_...",
  "attendanceDate": "2026-06-23",
  "type": "MISSED_SIGN_OUT",
  "targetRecordCode": "SATT_...",
  "requestedSignOutAt": "2026-06-23T13:00:00Z",
  "reason": "stayed for parent meeting",
  "confirmedSoftTime": false,
  "method": "APP",
  "timeZone": "America/New_York"
}
```
- `confirmedSoftTime: true` → confirm path (§8.2); `requestedSignOutAt` equals `softSignOutAt`.
- Response returns the created (or existing pending) regularization, plus whether sign-in is now unblocked.

### 9.3 List my requests (staff)
```
GET /staff-attendance-regularizations?staffCode={code}&status={PENDING|APPROVED|CANCELLED}&page=0&size=20&sort=createdAt,desc
```

### 9.4 Cancel (staff)
```
POST /staff-attendance-regularizations/{code}/cancel
```

### 9.5 Admin inbox (pending)
```
GET /staff-attendance-regularizations?schoolCode={code}&status=PENDING&page=0&size=20&sort=createdAt,asc
```
Paginated (server default 10 — mirror the overview/profile convention; the app loads more on scroll).

### 9.6 Approve single (admin, optional modify)
```
POST /staff-attendance-regularizations/{code}/approve
```
```json
{
  "signInAt": null,
  "signOutAt": "2026-06-23T13:15:00Z",   // omit/null = approve as submitted
  "note": "confirmed with lead teacher",
  "timeZone": "America/New_York"
}
```
Applies (§8.4) and returns the updated request + recomputed day summary (optional).

### 9.7 Bulk approve (admin)
```
POST /staff-attendance-regularizations/approve-all
```
```json
{ "schoolCode": "SCH_...", "codes": ["SREG_...", "SREG_..."] }
```
- `codes` optional; when omitted, approve **all currently PENDING** for the school.
- Approves each **as submitted** (no per-item modification).
- Response summarizes results (approved count + any skipped with reason).
```json
{
  "success": true,
  "data": { "approved": 12, "skipped": [ { "code": "SREG_...", "reason": "already decided" } ] }
}
```

> **Concurrency:** bulk approve should operate on a snapshot and skip items already decided (idempotent), returning them under `skipped` rather than failing the whole batch.

---

## 10. Non-functional requirements

### 10.1 Timezone
- All wall-clock inputs (the staff's actual time, admin's modified time) are entered in **school-local** time and converted to UTC using the school IANA `timeZone` (the app already does this via `Av2TimeZone`). Store UTC; keep `time_zone` on the row for reproducibility. `attendance_date` is the **school-local calendar date**.

### 10.2 Recompute
- Approval/confirm must trigger the existing overtime recompute for the affected `(staff, date)` so `/profile` reflects the change immediately. Prefer synchronous recompute on approval; bulk approve may recompute affected days in a batch.

### 10.3 Idempotency & concurrency
- Create: partial-unique on pending prevents duplicates.
- Approve / bulk approve: idempotent, snapshot-based, per-item skip on conflict.

### 10.4 Audit
- Every state change records who/when (`created_by`, `decided_by`, timestamps). Keep the original `soft_sign_out_at` and `requested_*` alongside `applied_*` so the correction trail is fully reconstructable.

### 10.5 Notifications (optional but expected)
- On **create** → notify school admins ("N regularization requests need approval").
- On **approve** → notify the staff. (Reuse the existing notification channel; not required for v1 functional correctness.)

---

## 11. Effect on existing endpoints (summary)

| Existing endpoint | Change |
|---|---|
| `POST /staff-attendance-records/sign-in` | Reject/deny while an unresolved soft sign-out gate exists (per §8.3 policy). |
| `POST /staff-overtime-records/calculate` | Treat provisional (`SYSTEM`, unresolved) sessions per §8.1; finalize on confirm/approve. |
| `POST /staff-overtime-records/profile` | Return `needsAttention = true` for days with provisional sessions; reflect corrected hours after approval. |
| `staff-attendance-records` (session row) | New fields: `signed_out_method` values, `is_regularized`, `regularization_code`, provisional semantics. |

---

## 12. Open decisions (need product/backend sign-off)

1. **Provisional accounting (§8.1):** exclude the whole session, or count worked time only up to a cutoff (e.g., last known activity / geofence exit)? Default proposal: **exclude the post-sign-in-to-soft-time as provisional; show 0 counted until resolved.**
2. **Confirm auto-approval (§8.2):** does confirming the system time skip admin approval? Proposal: **yes** (it's accepting existing data).
3. **Gate vs. sign-in (§8.3):** does a `PENDING` request unblock next sign-in? Proposal: **yes** — don't block staff on admin latency.
4. **Reject removal:** confirm the enum keeps `REJECTED` reserved but no app path creates it.
5. **Overnight sessions:** define the school "day window" for validating `signOutAt` that crosses midnight.
6. **Bulk approve scope:** approve *all pending* vs. only a selected subset — the app supports both (`codes` optional); confirm default behavior when `codes` omitted.

---

## 13. Appendix — client mapping (for reference)

The mobile module `attendance_regularization` already models:
- `MissedSignout` → §9.1 gate item.
- `RegularizationRequest` (`RegType`, `RegStatus`) → §7.1 row.
- Single staff sheet (`reg_resolve_sheet`) → §9.2 (confirm/correction in one submit; returns `confirmedSoftTime`).
- Admin decision sheet (`reg_decision_sheet`) → §9.6 (approve + optional modify + note; **no reject**).
- Admin inbox "Approve all (N)" → §9.7 (bulk approve).

The attendance detail module (`attendance_v2`) already consumes `sign-in`/`sign-out`, `staff-attendance-records/daily/{code}` (PATCH), `staff-absence-records`, and `staff-overtime-records/{profile,calculate}` — regularization plugs into the same records and recompute path.
```
