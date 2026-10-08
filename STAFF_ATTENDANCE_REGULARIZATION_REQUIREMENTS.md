# Staff Attendance Regularization — Requirements

| | |
|---|---|
| **Status** | Requirements for review (product + backend + mobile/web) |
| **Module** | Builds on `attendance_v2` (staff attendance & overtime) |
| **Author** | Tech Lead |
| **Date** | 2026-06-24 |

---

## 1. Why this exists

Staff forget to sign out (and sometimes to sign in). Today that either leaves an **open record** or gets **silently auto-closed at school end time** — which steals real overtime from someone who stayed late, and means nobody knows the record is wrong. Regularization makes correction **explicit, owned, and auditable**:

- The system never silently fabricates time as if it were real.
- A missed punch is **resolved at the point the staff returns** (not piled up for a month-end cleanup).
- An admin/manager approves, modifies, or rejects each correction, with a full trail.

This matches how Keka, Zoho People, greytHR, Darwinbox and Deputy handle "attendance regularization / time correction."

---

## 2. Key concepts (definitions)

| Term | Meaning |
|---|---|
| **Soft sign-out** | When a sign-in has no matching sign-out by end of that day, the system closes the session at the **school's end time for that date** and marks it `SYSTEM_CLOSED` (provisional, not a real punch). |
| **Needs regularization** | A day/record flagged because it was soft-closed (or has a missed sign-in / open session) and hasn't been confirmed or corrected. |
| **Regularization request** | A staff-raised request to confirm or correct a flagged record (e.g. "I actually left at 3:30 PM, not 2:00 PM"). |
| **Approver** | The person who approves/modifies/rejects a request (default: school admin; see §6 hierarchy). |
| **Gate** | The block/prompt shown to a staff member on their **next sign-in** when they have an unresolved soft sign-out from a prior day. |

---

## 3. Personas

| Persona | Capability |
|---|---|
| **Staff** (teacher/lead/associate) | Sees their own flagged days; raises regularization requests; sees request status. |
| **School / Org Admin** | Receives requests; approves / modifies / rejects; can also directly edit/delete records (already built). Configures regularization policy per school. |
| **Parent / Kiosk** | Not involved. |

---

## 4. Core flow (the heart of the feature)

```
Day D
  └─ Staff signs IN (e.g. 08:00) … forgets to sign OUT.

End of Day D (scheduled, per school end time)
  └─ System SOFT SIGN-OUT at school end time (e.g. 17:30).
       record.signedOutMethod = SYSTEM
       record.closeType       = SYSTEM_CLOSED
       day.needsRegularization = true
     (No bulk collection — this single record is now flagged.)

Day D+1
  └─ Staff opens app / attempts to SIGN IN.
       System finds unresolved soft sign-out(s) from prior day(s).
       → Shows the REGULARIZATION GATE (pop-up).

Gate (per-school: MANDATORY or OPTIONAL)
  ├─ Option A "I left at 17:30 (school end)"  → confirm soft time → resolved (see §4.1)
  ├─ Option B "I left at a different time"     → raise REGULARIZATION REQUEST
  │     (pick actual sign-out time + reason) → status PENDING → notify approver
  └─ Option C "Skip for now"  (only if OPTIONAL) → stays flagged in "Needs attention"

  MANDATORY: staff cannot complete the Day D+1 sign-in until A or B is done.
  OPTIONAL : staff may Skip and proceed; the flag remains until resolved.

Approver (admin) gets a notification
  ├─ APPROVE  → record sign-out set to requested time
  ├─ MODIFY   → approver changes the time, then approves
  └─ REJECT   → soft sign-out (school end) stands; record stays flagged/rejected (per policy)

On APPROVE/MODIFY
  └─ record updated, closeType = REGULARIZED, day recalculated (overtime corrected),
     requester notified.
```

### 4.1 The "confirm school-end time" fast path (recommended addition)
Not every missed sign-out is wrong — many staff genuinely leave at school end. Forcing a full approval for those creates noise. So the gate offers a **one-tap confirm**: "Yes, I left at [school end time]." This resolves the flag **without** an approval cycle (it's accepting the system default), but is still **logged** (who confirmed, when). Only **Option B (different time)** needs approval. *Product decision: confirm whether self-confirmation auto-resolves or still needs a light approval — see §15 Q1.*

---

## 5. Per-school configuration

All knobs live in school attendance settings (effective-dated):

| Setting | Values | Default | Notes |
|---|---|---|---|
| `softSignOutEnabled` | on/off | on | Whether to soft-close open sessions at school end. |
| `schoolEndTime` (per weekday) | time | from schedule | Source of the soft sign-out time; from `childcare_schedules`. |
| `regularizationGate` | `MANDATORY` / `OPTIONAL` / `OFF` | `MANDATORY` | Whether the next-sign-in gate blocks, prompts, or is disabled. |
| `regularizationWindowDays` | int | 7 | How many days back a staff may regularize (older = admin-only). |
| `selfConfirmAutoResolves` | on/off | on | Whether "I left at school end" resolves without approval (§4.1). |
| `approvalRouting` | `MANAGER` / `SCHOOL_ADMIN` / `ORG_ADMIN` | `SCHOOL_ADMIN` | Who approves (see §6). |
| `lockAfterPayrollFinalized` | on/off | on | No regularization for a finalized payroll period. |

---

## 6. Approval workflow & hierarchy

**Approver resolution** (first match):
1. Staff's assigned **approval manager** (if `approvalRouting = MANAGER` and one is set).
2. Else the **school admin**.
3. A **school admin's** own requests route to the **organization admin** (if the org has one).
4. The **topmost admin** (org admin, or school admin when no org admin) is **self-approved** — their corrections apply immediately but still write an audit row (status `APPROVED`, decidedBy = self). The topmost admin never needs to request.

The approver is **snapshotted onto the request at creation**, so changing a manager later doesn't orphan pending requests. If an approver is deactivated, pending requests **re-route up the chain**.

### Request state machine
```
        ┌──────────┐  approve / modify+approve   ┌──────────┐
create→ │ PENDING  │───────────────────────────▶ │ APPROVED │ → record updated, day recalculated
        │          │  reject                      ├──────────┤
        │          │────────────────────────────▶│ REJECTED │ → soft time stands; stays flagged
        │          │  cancel (requester, while PENDING)
        │          │────────────────────────────▶│ CANCELLED│
        └──────────┘
```
Terminal states are immutable; a rejected request can be re-raised. No request may target a date inside a **finalized payroll period** unless an admin reopens it.

---

## 7. Regularization types

| Type | Trigger | What the request carries |
|---|---|---|
| `MISSED_SIGN_OUT` | soft sign-out (the primary case) | actual sign-out time + reason |
| `MISSED_SIGN_IN` | record exists with no sign-in / staff says they were in earlier | actual sign-in time + reason |
| `MISSED_FULL_DAY` | no record at all but staff worked | sign-in + sign-out + classroom + reason (creates a record on approval) |
| `TIME_CORRECTION` | times exist but are wrong | corrected in/out time + reason |

v1 priority: **MISSED_SIGN_OUT** (your described flow). Others share the same request + approval plumbing.

---

## 8. The next-day gate (pop-up) — detailed UX

**When:** staff opens the app or taps "Sign in" on Day D+1 and has ≥1 unresolved soft sign-out within `regularizationWindowDays`.

**Pop-up content:**
- Title: "Finish yesterday first" (or per-date).
- Body: "You didn't sign out on **[date]**. We marked you out at **[school end time]**. Confirm or correct it before signing in today."
- Actions:
  - **"I left at [school end]"** → confirm (fast path, §4.1).
  - **"I left at a different time"** → opens the regularization form (time picker + reason, required).
  - **"Skip for now"** → only when `regularizationGate = OPTIONAL`.

**Backlog:** if multiple prior days are unresolved, resolve **oldest-first**, one card at a time (or a short list). The gate clears only when all in-window items are handled (MANDATORY) or skipped (OPTIONAL).

**Mandatory vs optional:**
- `MANDATORY`: the Day D+1 sign-in button stays disabled until the prior item is confirmed or a request is raised. (A raised-but-pending request unblocks sign-in — the staff did their part; approval is async.)
- `OPTIONAL`: staff can skip; the item stays in the **Needs attention** filter (already in the module) with a persistent banner until resolved.

> A **pending** request should unblock the next sign-in even in MANDATORY mode — the staff has fulfilled the obligation; waiting on the admin shouldn't block their work.

---

## 9. Soft sign-out & overtime/payroll interaction

- A `SYSTEM_CLOSED` session counts worked time **only up to the school end time** — never beyond. So an un-regularized day can **under-count** overtime (safe default: don't pay OT the system isn't sure happened).
- On **approval/modify**, the real sign-out replaces the soft one, the day is **recalculated** (overtime corrected), and the change is audited.
- A day with a **pending or rejected** regularization is **provisional** for payroll. Payroll finalization should surface unresolved items (a "X days need regularization" gate before finalize — ties into the payroll-lock work).
- Until resolved, the module already shows these under **Needs attention** with the amber "auto signed-out" flag.

---

## 10. Notifications

| Event | Recipient | Channel |
|---|---|---|
| Soft sign-out created (end of day) | Staff | push + in-app ("You forgot to sign out today") |
| Regularization request raised | Approver | push + in-app + badge |
| Pending > 24–48h | Approver | reminder push |
| Approved / modified / rejected | Requester | push + in-app |
| Weekly: unresolved regularizations | Admin | digest |

---

## 11. Data model (backend)

### `attendance_regularization_request` (new)
```
code                 PK
staffCode            requester / beneficiary
schoolCode, organizationCode
attendanceDate
type                 MISSED_SIGN_OUT | MISSED_SIGN_IN | MISSED_FULL_DAY | TIME_CORRECTION
targetRecordCode     FK → staff_attendance_record (null for MISSED_FULL_DAY)
requestedSignInAt    nullable (UTC)
requestedSignOutAt   nullable (UTC)
reason               required text
status               PENDING | APPROVED | REJECTED | CANCELLED
approverCode         snapshot at creation
grantedSignInAt      nullable (when approver modified)
grantedSignOutAt     nullable
decidedByCode, decidedAt, decisionNote
createdAt, updatedAt
```
Constraint: at most one `PENDING` request per `(staffCode, attendanceDate, targetRecordCode)`.

### `staff_attendance_record` additions
- `closeType`: `NORMAL | SYSTEM_CLOSED | REGULARIZED | ADMIN_CORRECTED`
- `needsRegularization`: bool (derived/stored)
- `sourceRequestCode`: FK → the request that last modified it (audit)

### Audit
Every soft-close, confirm, request, and decision writes to the existing generic audit log (who/what/before/after/when).

---

## 12. API requirements

```
# Detection (gate)
GET  /api/v1/staff-overtime-records/pending-regularizations?staffCode=
     → list of unresolved soft sign-outs / missed punches within the window
       (date, recordCode, softSignOutAt, schoolEndTime, type)

# Raise
POST /api/v1/staff-attendance-regularizations
     { staffCode, attendanceDate, type, targetRecordCode,
       requestedSignInAt?, requestedSignOutAt?, reason }

# Self-confirm fast path
POST /api/v1/staff-attendance-regularizations/confirm-soft-signout
     { staffCode, recordCode }              # accepts school-end time

# Approver inbox
GET  /api/v1/staff-attendance-regularizations?role=approver&status=PENDING
PUT  /api/v1/staff-attendance-regularizations/{code}/approve   { note? }
PUT  /api/v1/staff-attendance-regularizations/{code}/modify-approve
     { signInAt?, signOutAt?, note? }
PUT  /api/v1/staff-attendance-regularizations/{code}/reject     { note }
PUT  /api/v1/staff-attendance-regularizations/{code}/cancel     # requester

# Requester view
GET  /api/v1/staff-attendance-regularizations?role=requester&staffCode=
```
- Approve/modify is **transactional**: update the target record (`closeType = REGULARIZED`, `sourceRequestCode` set), write audit, recompute the day, notify.
- The overview's day should expose `needsRegularization` + (for the gate) the soft sign-out details and the linked request status.

---

## 13. Edge cases

| Case | Handling |
|---|---|
| Staff legitimately left at school end | Fast-path confirm (§4.1); no approval noise. |
| Multiple unresolved prior days | Gate resolves oldest-first; sign-in unblocks only when all in-window items handled (MANDATORY). |
| Missed sign-IN (not out) | `MISSED_SIGN_IN` request; same approval flow. |
| Whole day missed (no record) | `MISSED_FULL_DAY`; record created on approval. |
| School end time not configured | Fall back to a school default; flag for admin; don't soft-close arbitrarily. |
| Overnight / split shifts | Soft-close each open session at the relevant school end; one request per record. |
| Approver inactive / changed | Approver snapshotted; re-route up chain on deactivation. |
| Payroll already finalized | Block regularization unless admin reopens the period (audited). |
| Window expired (> N days) | Staff can't self-regularize; admin-only correction (existing edit). |
| Pending request + new sign-in | Pending unblocks next sign-in (MANDATORY); staff did their part. |
| Duplicate request | One PENDING per record/date; re-raise only after a terminal state. |
| Admin direct edit vs request | Admin can still edit/delete directly (already built); that resolves the flag too, audited. |

---

## 14. Acceptance criteria

- **AC1** A sign-in with no sign-out by school end → record soft-closed at school end, `SYSTEM_CLOSED`, day flagged `needsRegularization`.
- **AC2** Next-day app open / sign-in with an unresolved prior soft sign-out → gate pop-up shown.
- **AC3** MANDATORY mode → sign-in blocked until the prior item is confirmed or a request raised; a **pending** request unblocks it.
- **AC4** OPTIONAL mode → staff may Skip; item persists in Needs attention with a banner.
- **AC5** Raising a request notifies the resolved approver; request is PENDING.
- **AC6** Approver can **approve / modify+approve / reject**; on approve/modify the record updates, `closeType = REGULARIZED`, day recalculated, requester notified.
- **AC7** Self-confirm "left at school end" resolves the flag (per `selfConfirmAutoResolves`) and is audited.
- **AC8** Every transition is audited (requester, asked vs granted, decider, timestamps).
- **AC9** No regularization on a finalized payroll period unless reopened.
- **AC10** Un-regularized days count worked time only up to school end (no speculative OT).

---

## 15. Open questions (product)

1. **Self-confirm**: does "I left at school end" auto-resolve, or still need a light admin acknowledgement?
2. **Mandatory default**: is the gate `MANDATORY` org-wide, or per-school (recommend per-school, default MANDATORY)?
3. **Approver**: school admin only for v1, or honor a per-staff manager from day one?
4. **Window**: default regularization window (7 days?) and what happens after.
5. **Reject outcome**: does a rejected missed-sign-out keep the school-end time (paid to end) or mark the day as needing admin action / unpaid beyond a point?
6. **Missed sign-IN scope**: in v1, or sign-out only first?

---

## 16. Phasing

| Phase | Scope |
|---|---|
| **P1** | Soft sign-out + `SYSTEM_CLOSED` flag + Needs-attention surfacing (largely built) + the next-day **gate** (MANDATORY/OPTIONAL) + raise `MISSED_SIGN_OUT` + self-confirm. |
| **P2** | Approver inbox + approve/modify/reject + notifications + audit. |
| **P3** | Other types (missed sign-in, full day, time correction), approval hierarchy, payroll-lock integration. |

---

## 17. How it maps to what's already built (`attendance_v2`)
- **Soft sign-out marker** = the `SYSTEM` / `closeType` fields the module already reads (`signOutSource = system`, amber "by System").
- **Needs attention** filter + banner already exist → reuse for un-regularized days.
- **Admin edit/delete** already exists → becomes the admin's "modify" path; the approval flow is staff-initiated on top.
- New: the **gate pop-up**, the **regularization request** entity/endpoints, and the **approver inbox**.
