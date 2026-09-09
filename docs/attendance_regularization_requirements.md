# Attendance Regularization — Backend Requirements & Data Model

**Status:** Design locked (decisions §12 resolved)
**Revision:** Data-model update — approval columns renamed, `CANCELLED` dropped (create + edit only), suggested-time tracking and `is_regularized` removed.
**Owner:** Mobile (WowCare) → Backend
**Scope:** Adds a *regularization* workflow on top of the existing Staff Attendance / Overtime module (`attendance-ms`), over the real `staff_attendance_record` table.
**Audience:** Backend engineers designing the API + schema.

This spec matches the client already implemented in module `attendance_regularization`. It **reuses** the existing attendance records; it does not replace them. Field names below match the real `staff_attendance_record` table.

---

## 1. Problem statement

Staff frequently **forget to sign out** — or an admin signs them in (e.g. bulk / on their behalf) and no sign-out ever happens. **Two** things can be true of that row on a past day, and both need regularizing:

```
status = 'SIGNED_IN',  signed_out_at = NULL             -- still open (scheduler off, or hasn't fired)
status = 'SIGNED_OUT', signed_out_method = SYSTEM       -- scheduler auto-closed it on a guessed time
```

The second case exists because the school's auto sign-out scheduler, when enabled, eventually closes the row itself — writing `signed_out_at`, `status = 'SIGNED_OUT'` and `signed_out_method = SYSTEM`. **A scheduler close is not a staff-confirmed sign-out**, so it must hit the same gate rather than being treated as done.

> **Backend prerequisite.** `AutoSignOutExecutionService` currently computes and writes `total_worked_minutes` when it auto-closes a row. On the `SYSTEM` path it must write **`0`** instead. Two reasons: the day stays uncounted (§8.1), and the staff **sees 0 hours** — which is the nudge to raise the request. This is an **accounting** requirement only; detection does **not** depend on it (§9.1), so the gate works correctly whether this change ships before or after. **Keep `signed_out_at` as written** — the scheduler's guess is the best suggested sign-out time for the gate sheet. *(Tracked as a change to `AutoSignOutExecutionService`, outside this doc's API surface.)*

Either way — still open, or auto-closed on a guess — the day silently sits incomplete until a human confirms or corrects it.

Regularization makes this explicit and correctable:

1. Before that staff can be signed in again — **by themselves or by an admin** — the app **blocks sign-in** on the open past session.
2. Whoever signs in **raises the request** — stating the actual sign-out time and a reason. Raising is **mandatory**; there is no "confirm silently."
3. If **staff** raised it, an **admin approves** it (optionally **modifying** the time with a note). If an **admin** raised it, the backend **auto-approves** it — the admin is the approver. There is **no reject and no cancel**; a request that is wrong is **edited** while it is still pending (§9.4).
4. Only on **approval** is the sign-out written onto the attendance row and the day counted.

> **Headline rule:** An open past session counts as **0** until its regularization is **approved**. A staff-raised request unblocks the next sign-in but does **not** by itself count the hours; an admin-raised one is approved and counted immediately.

> **Backlog is impossible by design:** because the gate blocks *every* sign-in path (§8.3), a staff can never carry more than **one** unresolved missed sign-out — so there is no multi-day catch-up flow to build.

---

## 2. Scope

**In scope**
- Detecting open past sessions and exposing them (the "gate").
- A regularization request lifecycle: **create → edit (while pending) → approve/modify → apply → recompute**.
- Staff self-service (raise, list, **edit their own pending request**), **admin raise-on-behalf (auto-approved)**, and admin approval (single approve/modify + **multi-select bulk approve**).
- **Bulk sign-in**: batch gate check + batch raise, so an admin signing in many staff at once can clear several blocked staff in one action (§5.1c).
- Applying the approved sign-out onto `staff_attendance_record` and recomputing overtime.

**Out of scope (v1) — model must not preclude**
- Missed **sign-in** and **full-day** corrections — deliberately **not** pre-modelled (no `type` column today); they need a nullable target + a create-the-row apply path, so treat them as a separate feature (§7.5).
- **Cancel / withdraw** of a raised request — replaced by edit-while-pending (§8.4).
- SLAs, escalation.

---

## 3. Actors & roles

| Actor | Capabilities |
|---|---|
| **Staff** | See their own open-session gate; raise the request; list their own requests; **edit their own request while it is `PENDING`**. |
| **Admin** (`ORGANIZATION_ADMIN` / school admin) | List pending requests for the school; approve (with optional modify + note); **multi-select bulk approve**. **Raise on a staff's behalf** when signing them in — such requests are **auto-approved**. Edit a pending request for their school. **No reject, no cancel.** |

Auth reuses the existing interceptor + `X-Organization-Code` / `X-School-Code` headers. Staff endpoints are scoped to the authenticated staff; admin endpoints require an admin role for the school.

---

## 4. Glossary

| Term | Meaning |
|---|---|
| **Day's last session** | A staff can sign in and out **many times in one day**, so one day has several `staff_attendance_record` rows. The row evaluated is the **last** one: the greatest `signed_in_at` for that `(staff_code, attendance_date)`, tie-broken on `id`. Earlier sessions of the same day are not regularized. |
| **Open session** | A **day's last session** not genuinely closed by a human: either `status = 'SIGNED_IN'` with no `signed_out_at`, **or** closed by the scheduler (`signed_out_method = SYSTEM`). |
| **Missed sign-out** | An **open session on a past day** (`attendance_date < today`, school-local). The unit of regularization is one **`(staff, date)`** pair — never more than one per day. |
| **Gate** | The mandatory blocker before the next sign-in (staff *or* admin-on-behalf): the staff's unresolved missed sign-out must be raised first. |
| **Suggested sign-out time** | The time pre-filled in the sheet, **computed at read time and never stored**: the scheduler's own `signed_out_at` if it auto-closed the row, else the school schedule's closing time for that weekday, else a 19:00 local cap. |
| **Raise** | Creating the request with the actual sign-out time + reason. Staff-raised → **PENDING**; admin-raised → auto-approved (§8.2b). |
| **Edit** | Changing the time and/or reason on a request that is still `PENDING` (§9.4). The only way to fix a wrong request — there is no cancel. |
| **Apply** | On approval (or immediately, for admin-raised), write the sign-out onto the attendance row and recompute the day. |

---

## 5. End-to-end flow

### 5.1 The gate — mandatory before **any** sign-in for that staff

> **Invariant (no backlog by construction):** the gate applies to **whoever performs the sign-in** — the staff themselves *or* an admin signing them in. Because the previous open day must be cleared before the next sign-in is accepted, a staff can never accumulate more than **one** unresolved missed sign-out **day**. There is therefore **no multi-day workflow** — the pile-up is prevented at the source rather than mopped up later.

> **One day = one unit, evaluated on the day's last session.** Within a single day a staff may legitimately sign in and out many times, so that day has many attendance rows. The gate looks only at the day's **last session**: its sign-out if one happened, otherwise its sign-in (§4). A day whose last session was genuinely signed out by a human is clear, even if an earlier session that day was left open. `open-sessions` therefore returns **at most one item per `(staff, date)`**.

1. On app open / attempted sign-in, the client calls **GET open-sessions** for the staff.
2. If an open past session exists, sign-in is **blocked** and **one focused sheet** opens: the date, the editable suggested sign-out time (pre-filled, computed server-side), the consequence, and a reason field.
3. Submit — one shape only: the **actual sign-out time** plus a **reason** (§8.2). The pre-filled suggestion is a convenience for the raiser; the server does not track whether it was kept or changed.
4. Once the request exists, sign-in is unblocked.
   - **Staff raised it** → request is `PENDING`; the day stays **uncounted** until an admin approves. The staff can still **edit** it while it is pending.
   - **Admin raised it** (signing the staff in) → **auto-approved and applied immediately** (§8.2b); the day is counted at once.

### 5.1b Admin — signing in a staff who never signed out
The admin hits the same gate with admin-flavoured copy ("Sign-out missing", names the staff, "your correction is approved automatically"). They set the sign-out, save, and can then sign the staff in. This is the normal path for admin-driven / bulk sign-ins.

### 5.1c Admin — bulk sign-in when several staff are blocked

The gate is per-staff, but **bulk sign-in is per-batch** — one admin action can hit many blocked staff at once (worst case: a school's very first morning, when no gate has ever run). The flow must not degrade into N sequential mandatory sheets.

1. Before signing in, the client checks **all selected staff in one call** (§9.1b).
2. **Unblocked staff sign in immediately** — they are not held up by someone else's open day.
3. The blocked staff appear on **one consolidated sheet** — **one row per `(staff, date)`**, that day's last session (§4) — each pre-filled with that person's suggested sign-out time. The admin either:
   - **Close all N & sign them in** — one tap; each row is raised and (being admin-raised) auto-approved (§8.2b), then those staff are signed in; or
   - **corrects individual rows** first (marked "edited", with undo), with one shared reason covering the batch; or
   - **Skips** — the unblocked staff still sign in; the blocked ones are left for later.
4. The batch raise goes through **one call** (§9.2b), not N.

> **Cold start.** On a school's first day, a large share of staff may be blocked at once. After that the gate keeps it to the day's stragglers. Expect this and don't treat it as a defect.

### 5.2 Staff — my regularizations
- List of the staff's requests with status (`Pending` / `Approved`), requested time, reason, approval info.
- Staff can **edit** a `PENDING` request — time and/or reason (§9.4). Once approved it is read-only.

### 5.3 Admin — approval inbox
- List of **pending** requests for the school (paginated, server default 10 — same convention as `/staff-overtime-records/profile`).
- **Individual:** tap a tile → approve sheet (reason shown, editable time, "reason for change" note) → **Approve** (optionally modified). No reject.
- **Bulk:** **multi-select** tiles, then **Approve selected (N)** — approves the chosen requests **as submitted**. Remaining or tricky ones are handled individually. (There is no "approve everything at once" button; the admin always chooses the set.)

---

## 6. Request lifecycle (state machine)

```
                        raised by STAFF
   [open past session] ─────────────────► [PENDING] ──► sign-in unblocked (day still uncounted)
            │                              │    ▲
            │                              │    └── edit (raiser or admin, while PENDING)
            │                              │        time and/or reason — status unchanged
            │                              │
            │                              └── approve (± modify) ──► [APPROVED] ─ apply → row updated + recomputed
            │
            │           raised by ADMIN  (auto-approve, same transaction)
            └────────────────────────────────────────► [APPROVED] ─ apply → row updated + recomputed
```

- Statuses: **`PENDING`, `APPROVED`** — two values only.
- **No `REJECTED` state and no `CANCELLED` state.** Admins approve or leave pending; a wrong request is **edited**, not withdrawn. Do not add either enum value.
- `APPROVED` is terminal **and immutable** — no edit, no re-open. Approval applies the correction atomically with the status change (§8.7).

---

## 7. Data model

### 7.1 Decision: **separate table** + one denormalized pointer on the attendance row

Store the workflow in its own table, and denormalize only the read-optimizer onto `staff_attendance_record`. Rationale in §11.

### 7.2 New table: `staff_attendance_regularization`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `code` | string | e.g. `SREG_XXXX` |
| `organization_code` | string | |
| `school_code` | string | |
| `staff_code` | string | |
| `attendance_date` | date | School-local calendar date being corrected |
| `attendance_code` | string **NOT NULL** | FK → `staff_attendance_record.code` — the open row being closed. Enforceable FK, because every request targets an existing row (see §7.4) |
| `requested_sign_out_time` | timestamptz | What the raiser asked for |
| `reason` | text **NOT NULL** | Raiser's reason — always required, non-blank (§8.2). Never nullable and never cleared by an edit |
| `status` | enum | `PENDING` \| `APPROVED` |
| `approved_sign_out_time` | timestamptz, nullable | Final value written on approval — **may differ** from `requested_sign_out_time` if the admin modified it. **Do not derive this from the attendance row** (§7.4) |
| `approval_by_code` | string, nullable | Admin user code. The display **name is resolved at read time** into the DTO, not stored (§7.5) |
| `approval_at` | timestamptz, nullable | |
| `approval_note` | text, nullable | Admin "reason for change" |
| `raised_by_code` | string | User code of whoever raised it (staff or admin) |
| `method` | enum/int | `APP` \| `WEB` (align with the attendance method enum style) |
| `created_at` / `created_by_code` | | |
| `updated_at` / `updated_by_code` | | Bumped on edit (§9.4) |

**Indexes**
- `(school_code, status)` — admin inbox.
- `(staff_code, status)` — staff list + gate.
- `(attendance_code)` — join back to the row.
- Partial unique `(attendance_code) WHERE status = 'PENDING'` — one active request per open row (idempotent raise).

> **No soft delete.** This table has no `deleted_at` / `deleted_by_code`: a regularization row is a permanent audit record of a corrected day. Nothing removes it — a wrong request is edited while pending, and an approved one is immutable. Note that `staff_attendance_record` **keeps** its soft delete, so the detection query still filters `deleted_at IS NULL` on the attendance side (§9.1).

> **Auto-approval is derived, not stored.** With `raised_by_role` and `auto_approved` dropped, "was this reviewed by a second person?" is answered by comparing columns: `approval_by_code = raised_by_code` ⇒ the raiser approved their own request, i.e. the admin-raised auto-approval path (§8.2b). The raiser's *role* is not persisted — it is enforced server-side at creation from the authenticated token and never trusted from the client.

> **Single-purpose table, generic name.** The table intentionally models **only missed sign-out** (§7.5). Keep the **name generic** (`staff_attendance_regularization`, *not* `staff_missed_signout_request`): the name is the expensive thing to change when more correction kinds arrive; a `type` column is not.

### 7.3 Denormalized pointer added to `staff_attendance_record`

The row already has: `code` (`STAR_…`), `staff_code`, `attendance_date`, `signed_in_at`, `signed_in_by_code`, `signed_in_method` (**int enum**), `signed_out_at`, `signed_out_by_code`, `signed_out_method` (int enum), `status` (`SIGNED_IN`/`SIGNED_OUT`), `total_worked_minutes`, `current_classroom_code`, `primary_classroom_code`, org/school + audit/soft-delete.

Add:

| Column | Type | Notes |
|---|---|---|
| `signed_out_method` | int enum | **Add a value for `REGULARIZED`** (admin-applied correction). Written on apply — when the row was previously auto-closed by the scheduler (`SYSTEM`), approval **overwrites** it. An approved regularization is always the final, authoritative sign-out method for that row, never the scheduler's guess. **This overwrite is what clears the gate.** |
| `regularization_code` | string, nullable | Back-pointer to the applied `staff_attendance_regularization.code`. |

> **No `is_regularized` flag and no `is_provisional` flag.** Both are redundant. "This day was corrected" is already expressed two ways on the row itself: `signed_out_method = REGULARIZED`, and `regularization_code IS NOT NULL`. "Not yet corrected" is `signed_out_at IS NULL` or `signed_out_method = SYSTEM`. A separate boolean would be a third copy of the same fact and could drift out of step with the method column.

### 7.4 Why `approved_sign_out_time` must be stored (not derived)

It is tempting to read the final time off the attendance row instead of storing it. **Don't.** The attendance row's `signed_out_at` is **mutable by an unrelated flow**: the staff-detail screen lets an admin PATCH `/staff-attendance-records/daily/{code}` with a new `signedOutAt` at any time. If a later edit overwrites it, the record of *what was actually approved* is gone.

Keep the pair:
- `requested_sign_out_time` — what the raiser asked for.
- `approved_sign_out_time` — what the approver committed.

Together they answer "staff asked 6:00 PM, admin approved 5:45 PM" forever, independent of later edits.

### 7.5 Deliberately excluded fields (and why it is safe to add them later)

Scope is **missed sign-out only**, so the following are **intentionally not columns**. Each is listed with the reason and the exact cost of adding it later — so this doesn't get re-litigated.

| Excluded | Why it's out | Cost to add later |
|---|---|---|
| `type` | Single-valued for this scope — a column with one possible value carries zero information, and forces an enum to be kept in sync across DB / backend / client for no benefit. Its absence also lets `attendance_code` be **NOT NULL + FK**. | **Trivial, lossless:** `ADD COLUMN type VARCHAR NOT NULL DEFAULT 'MISSED_SIGN_OUT'` — every existing row is correct by definition, no backfill logic. |
| `suggested_sign_out_at` | The suggestion is **computed at read time** from the scheduler's own `signed_out_at`, the school schedule, or the 19:00 cap (§9.1). Storing it would freeze a convenience default as if it were a decision. | Trivial: add as nullable and populate going forward. Historical rows would read NULL. |
| `confirmed_suggested_time` | Meaningless without the stored suggestion above, and no rule depends on it any more — reason is required either way (§8.2). | Trivial: add as nullable bool; only meaningful alongside the stored suggestion. |
| `raised_by_role` | Enforced from the authenticated token at creation, never trusted from the client, and not needed afterwards. The reviewed-vs-auto question is answered by `approval_by_code = raised_by_code` (§7.2). | Trivial: add as nullable enum. |
| `auto_approved` | Same — derivable from the two actor columns. | Trivial: add as nullable bool. |
| `current_classroom_code` | Context only, and already on the attendance row the request points at. The API can return it by reading the target row (§9.1). | Trivial: add as nullable. |
| `requested_sign_in_at` | Only meaningful for missed-sign-in / time-correction. Would be 100% NULL. | Trivial: add as nullable. |
| `approved_sign_in_time` | Same. | Trivial: add as nullable. |
| `approval_by_name` | **Derived data.** Names live in the user service; a stored copy goes stale on rename and violates single-source-of-truth. Resolve `approval_by_code` → name at read time into the DTO. | Not needed — it's a read concern, not storage. |
| `time_zone` | **Derivable** from `school_code` → school settings. The existing `staff_attendance_record` stores no timezone either, so persisting it here would make the correction more self-describing than the record it corrects. DST is **not** a reason to store it — an IANA zone plus a UTC instant resolves historical DST correctly. | Add as nullable if ever needed. |

**Two rules that come with these exclusions:**
1. **`timeZone` stays in the API request payload** (§9.2). The client sends **wall-clock school-local** time; the server needs the zone to convert to UTC. It is an *input parameter*, not stored state.
2. **Resolve `approval_by_code` → name in batch, per page** (one lookup for the ~10 codes on an inbox page). A per-row cross-service lookup is an N+1 and the main latency risk of dropping `approval_by_name`.

**Do NOT extend this trimming to:** `approved_sign_out_time` (§7.4 — it is the only record of what was actually approved), `requested_sign_out_time` (drop it and you lose what the staff asked for), `raised_by_code` / `approval_by_code` (together they are the whole actor trail, and the only way to tell an auto-approval from a reviewed one), and `reason` / `approval_note` (free text, not derivable).

**Deferred correction kinds.** Missed **sign-in** / **full-day** would have *no attendance row yet*, so they'd need `attendance_code` nullable and an apply path that **creates** a row. That is a schema change *plus* new business logic — treat it as a separate feature, not something today's columns should pre-empt. It remains the main reason the workflow lives in its own table (§11).

---

## 8. Business rules (locked)

### 8.1 Accounting — excluded until approved  *(Decision 1 ✔)*
- An unresolved past session counts as **0** everywhere: `/staff-overtime-records/profile` credits no regular/overtime/break for that day and returns `needsAttention = true`.
- Two mechanisms hold this together, and **both** are required:
  1. the scheduler writes `total_worked_minutes = 0` on a `SYSTEM` close (§1 prerequisite), so the stored value already reads zero; and
  2. **the overtime calculation must skip any day whose last session has `signed_out_method = SYSTEM`** — otherwise a recompute from `signed_in_at` → `signed_out_at` would silently re-credit the guessed hours and the staff would never see the 0 that prompts them to act. No `is_regularized` check is needed: approval overwrites the method to `REGULARIZED`, so a corrected day no longer matches this skip.
- On **apply** (approval), write `signed_out_at`, recompute `total_worked_minutes`, and re-run overtime `calculate` for `(staff, date)`.

### 8.2 Staff-raised: always pending, reason always required  *(Decision 2 ✔ — NO auto-approve)*
- A **staff-raised** request always lands `PENDING` — so admins are always **made aware** of the missed sign-out.
- **`reason` is mandatory on every raise.** With `confirmed_suggested_time` and the stored suggestion both removed, the backend has no reliable way to distinguish "kept the pre-filled time" from "typed the same time deliberately" — so there is no "confirm" shortcut, and every request carries a stated reason.
- **What "required" means in validation:** reject with `400` when `reason` is absent, empty, or whitespace-only — trim before checking, so a single space does not satisfy it. The rule applies identically to a single raise (§9.2), **every item** of a batch raise (§9.2b, shared or per-item), and an **edit** (§9.4), which may change `reason` but can never blank it. The column is `NOT NULL`, so a blank must be caught at the API layer rather than relied on to fail at the database.

### 8.2b Admin-raised: auto-approved by the backend
- When the **raiser is an admin** (role check server-side, not a client flag), the backend must create the request and **immediately approve + apply it in the same transaction**:
  - `status = APPROVED`, `raised_by_code` = the admin, `approval_by_code` = the same admin, `approval_at = now`, `approved_sign_out_time = requested_sign_out_time`;
  - then run the §8.7 apply + recompute.
- Rationale: the admin **is** the approver — a pending request they would approve themselves is pure friction.
- The request row is still written (never skipped) so the audit trail records that the day was corrected, by whom, and why. `approval_by_code = raised_by_code` is what marks it as auto-approved rather than reviewed (§7.2).
- Trust the **authenticated role**, not a request field: a staff token must not be able to self-approve by sending an "admin" flag.

### 8.3 Gate is mandatory for every sign-in path  *(Decision 3 ✔)*
- `POST /staff-attendance-records/sign-in` must **reject** a sign-in while that staff has a missed sign-out with **no request raised** — regardless of whether the caller is the staff or an **admin acting on their behalf** (incl. bulk sign-in: reject only the offending staff, report them back).
- Guard response: `409 REGULARIZATION_REQUIRED` carrying the unresolved open session(s) so the client can open the gate sheet directly.
- Once the request exists, sign-in is allowed: staff-raised stays `PENDING` (approval not required to sign in — don't block staff on admin latency); admin-raised is already approved.
- Because of this guard, at most **one** unresolved missed sign-out **day** can exist per staff at any time, and within that day only the **last session** is evaluated (§4, §5.1 invariant).
- **Bulk sign-in is partial-success, never all-or-nothing:** sign in everyone who passes, and return the blocked staff (with their open session) in the response so the client can open the consolidated sheet (§5.1c). Failing the whole batch because one person forgot to sign out is not acceptable.

### 8.4 No reject, no cancel — edit instead  *(Decision 4 ✔)*
- Admin actions are **approve** (± modify) or **leave pending**. There is **no reject** path or enum value.
- There is also **no cancel**. A request raised with the wrong time or reason is **edited in place** while it is still `PENDING` (§9.4) — by the raiser, or by an admin for their school. The `PENDING` row is never discarded, so the gate stays satisfied and the staff is not re-blocked mid-day by their own correction.
- An admin who disagrees with a pending request has two options: edit it, or approve it with a modified time and a note (§9.6). Both leave a complete trail.

### 8.5 Day window / overnight validation  *(Decision 5 ✔)*
- `requested_sign_out_time` must be **after** `signed_in_at` and within the **school working-day window** taken from the school schedule settings (working-hours end for that weekday).
- Safe assumption: schools close **before 19:00** local; use it as the default cap when schedule settings are missing. Reject times past the day's cap (protects against a corrected time crossing into the next day).
- The same validation applies to an **edit** (§9.4) and to an admin's **modified** approval time (§9.6).

### 8.6 Uniqueness / idempotency
- At most **one PENDING** request per `attendance_code` (partial unique). A repeat raise returns the existing PENDING request (idempotent) rather than a duplicate — the client should then offer **edit** rather than a second create.
- Approve is idempotent: approving an already-`APPROVED` request is a no-op returning current state.
- Edit is rejected once the request is `APPROVED` (`409`), since approval is terminal.

### 8.7 Apply (on approval), atomically
1. Set `status = APPROVED`, `approval_by_code`, `approval_at`, `approval_note`, and **`approved_sign_out_time`** (= the admin-modified time if provided, else `requested_sign_out_time`). Persist it — never re-derive it from the attendance row later (§7.4).
2. Update the target `staff_attendance_record` (always exists — `attendance_code` is NOT NULL): `signed_out_at = approved_sign_out_time`, `signed_out_by_code = <approver>`, `signed_out_method = REGULARIZED`, `status = SIGNED_OUT`, recompute `total_worked_minutes`, `regularization_code = <code>`.
3. Recompute overtime for `(staff_code, attendance_date)`.

### 8.8 Authorization
- Staff: create / list / **edit while pending** — **their own** only.
- Admin: list-pending, edit, approve, bulk-approve — scoped to their school.

---

## 9. API surface

Under `attendance-ms`, base `/api/v1`. UTC ISO-8601 in payloads (+ `timeZone` for interpretation). Auth + org/school headers as elsewhere.

### 9.1 Get the gate (open past sessions) — staff
```
GET /staff-attendance-regularizations/open-sessions?staffCode={code}
```
**Detection** — a staff can have **many sessions in one day**, so first reduce each `(staff_code, attendance_date)` to its **last session**, then test only that row:
```sql
WITH last_session AS (
  SELECT DISTINCT ON (staff_code, attendance_date) *
  FROM staff_attendance_record
  WHERE deleted_at IS NULL
    AND staff_code = :staffCode                 -- IN (:staffCodes) for §9.1b
    AND attendance_date < {today, school-local}
  ORDER BY staff_code, attendance_date, signed_in_at DESC, id DESC
)
SELECT * FROM last_session
WHERE (status = 'SIGNED_IN'  AND signed_out_at IS NULL)
   OR (status = 'SIGNED_OUT' AND signed_out_method = SYSTEM)
```
- **Last session** = greatest `signed_in_at` for that `(staff_code, attendance_date)`, tie-broken on `id DESC`. Check that row's sign-out; if it has none, that row *is* the last sign-in of the day. If it was genuinely signed out by a human, the day is clear — earlier sessions of the same day are never regularized.
- **`total_worked_minutes` is deliberately not part of the condition.** A staff who signs in and out normally in the morning and is then scheduler-closed on a later session has real worked minutes on the earlier row, and the last row's value depends on whether the §1 prerequisite has shipped — so testing minutes would make detection fragile and could miss a genuinely un-confirmed day. `signed_out_method = SYSTEM` is sufficient and unambiguous on its own: only the scheduler ever writes it, and a genuine sub-minute human session carries a human method, so it is never gated.
- **Implementation note:** the per-day reduction (`DISTINCT ON`, or `ROW_NUMBER() OVER (PARTITION BY staff_code, attendance_date ORDER BY signed_in_at DESC, id DESC)`) is not expressible in JPQL — this needs an `@Query(nativeQuery = true)` on `StaffAttendanceRecordRepository`, not a derived query method.
```json
{
  "success": true,
  "data": [
    {
      "attendanceCode": "STAR_...",
      "attendanceDate": "2026-08-03",
      "signedInAt": "2026-08-03T11:00:00Z",
      "signedInByCode": "USR-41d8db48",
      "suggestedSignOutTime": "2026-08-03T23:00:00Z",
      "classroomCode": "CLS_49E5BD28-A",
      "hasPendingRequest": false,
      "pendingRequestCode": null
    }
  ]
}
```
- `suggestedSignOutTime` is **computed per call, never stored** (§4, §7.5). Resolution order: **1)** the scheduler's `signed_out_at` if the row was SYSTEM-closed · **2)** the school schedule's closing time for that weekday · **3)** a 19:00 local fallback cap.
- `classroomCode` is read from the target attendance row (`current_classroom_code`), not from the request table.
- `pendingRequestCode` is returned when `hasPendingRequest = true`, so the client can go straight to **edit** (§9.4) instead of attempting a duplicate create.

### 9.1b Batch gate check — admin (bulk sign-in)
```
POST /staff-attendance-regularizations/open-sessions/batch
{ "staffCodes": ["STF_A", "STF_B", "STF_C"] }
```
Same detection as §9.1 — including the **last-session-per-`(staff, date)`** reduction — evaluated for many staff in **one** round trip; the single-staff GET would mean 50 calls before a 50-person bulk sign-in. `blocked` carries at most one entry per `(staff, date)`.

```json
{
  "success": true,
  "data": {
    "blocked": [
      { "staffCode": "STF_A", "staffName": "Sara Malik",
        "attendanceCode": "STAR_...", "attendanceDate": "2026-06-23",
        "signedInAt": "2026-06-23T11:00:00Z",
        "suggestedSignOutTime": "2026-06-23T21:30:00Z",
        "classroomCode": "CLS_...", "hasPendingRequest": false }
    ],
    "clear": ["STF_B", "STF_C"]
  }
}
```
- `blocked` carries `staffName` so the sheet can list people without a second lookup (resolved at read time, §7.5).
- `clear` lets the client sign those staff in straight away.

### 9.2 Raise a request — staff
```
POST /staff-attendance-regularizations
```
```json
{
  "staffCode": "STF_...",
  "attendanceDate": "2026-08-03",
  "attendanceCode": "STAR_...",
  "requestedSignOutTime": "2026-08-03T22:30:00Z",
  "reason": "stayed for parent meeting",
  "method": "APP",
  "timeZone": "America/New_York"
}
```
- `reason` is **required** (§8.2). There is no `confirmedSuggestedTime` field — the server does not track whether the pre-filled suggestion was kept.
- Returns the created request; if a `PENDING` request already exists for this `attendanceCode`, returns that one unchanged (idempotent, §8.6) — the client should switch to **edit** (§9.4).
- **Same endpoint for admins.** The server decides from the authenticated role: staff → `PENDING`; admin → created **and auto-approved/applied** (§8.2b). The response `status` tells the client which happened, so it can say "sent for approval" vs. "applied".
- No `type` field — this endpoint only handles missed sign-out (§7.5).
- `timeZone` **is required in the payload** even though it is not a column: the server needs it to convert the wall-clock time to UTC (§7.5, §10.1).

### 9.2b Batch raise — admin (bulk sign-in)
```
POST /staff-attendance-regularizations/raise-batch
{
  "timeZone": "America/New_York",
  "reason": "forgot to sign out",
  "items": [
    { "staffCode": "STF_A", "attendanceCode": "STAR_A", "attendanceDate": "2026-06-23",
      "requestedSignOutTime": "2026-06-23T21:30:00Z" },
    { "staffCode": "STF_B", "attendanceCode": "STAR_B", "attendanceDate": "2026-06-23",
      "requestedSignOutTime": "2026-06-23T22:15:00Z", "reason": "covered late pickup" }
  ]
}
```
- **Admin-only.** Each item follows §8.2b: created **and** auto-approved + applied.
- One shared `reason` applies to every item; a per-item `reason` overrides it. Since reason is mandatory (§8.2), either the shared value or a per-item value must be present for every item.
- Same validation per item as §9.2 (§8.5 window).
- Idempotent per item (§8.6): an item that already has a PENDING/APPROVED request is **skipped**, not an error.
- Mirrors `approve-selected` (§9.7) in shape:
```json
{ "success": true,
  "data": { "applied": 9, "skipped": [ { "attendanceCode": "STAR_C", "reason": "already resolved" } ] } }
```
- Each applied item runs the §8.7 apply + recompute; batching the recompute is acceptable.

### 9.3 List my requests — staff
```
GET /staff-attendance-regularizations?staffCode={code}&status={PENDING|APPROVED}&page=0&size=20&sort=createdAt,desc
```

### 9.4 Edit a pending request — staff (own) or admin (school)
```
PATCH /staff-attendance-regularizations/{code}
```
```json
{
  "requestedSignOutTime": "2026-08-03T21:45:00Z",
  "reason": "corrected — left after the staff meeting",
  "timeZone": "America/New_York"
}
```
- Allowed **only while `status = 'PENDING'`**. On an `APPROVED` request this returns `409` — approval is terminal (§6, §8.6).
- Both fields are optional individually, but at least one must be present. `timeZone` is required whenever `requestedSignOutTime` is sent.
- If `reason` is sent it must be non-blank (§8.2) — an edit can **replace** the reason but never clear it. Omitting `reason` leaves the existing value untouched.
- Re-runs the §8.5 window validation against the target row's `signed_in_at`.
- Updates `updated_at` / `updated_by_code`. `status` stays `PENDING`; the gate remains satisfied throughout, so the staff is never re-blocked by their own edit.
- **This replaces cancel.** There is no withdraw path — see §8.4.

### 9.5 Admin inbox (pending)
```
GET /staff-attendance-regularizations?schoolCode={code}&status=PENDING&page=0&size=10&sort=createdAt,asc
```

### 9.6 Approve — admin (single, optional modify)
```
POST /staff-attendance-regularizations/{code}/approve
```
```json
{ "signOutTime": "2026-08-03T22:45:00Z", "note": "confirmed with lead", "timeZone": "America/New_York" }
```
Omit `signOutTime` to approve **as submitted** (`approved_sign_out_time = requested_sign_out_time`); provide it to approve **with a modification** (it becomes `approved_sign_out_time`, and the original stays in `requested_sign_out_time`). `note` is stored as `approval_note`. Applies (§8.7).

### 9.7 Bulk approve — admin (selected set)  *(Decision 6 ✔)*
```
POST /staff-attendance-regularizations/approve-selected
```
```json
{ "schoolCode": "SCH_...", "codes": ["SREG_A", "SREG_B", "SREG_C"] }
```
- `codes` is **required** — the admin always chooses the set (multi-select in the UI). There is **no "approve all pending"** default.
- Each is approved **as submitted** (no per-item modify — modify is the single-approve path).
- Idempotent, snapshot-based; returns approved + skipped (already decided).
```json
{ "success": true, "data": { "approved": 2, "skipped": [ { "code": "SREG_C", "reason": "already decided" } ] } }
```

---

## 10. Non-functional

### 10.1 Timezone
Wall-clock inputs are **school-local**, converted to UTC via the school IANA zone (the client already does this via `Av2TimeZone` and sends `timeZone` in the payload). **Store timestamps as UTC (`timestamptz`); the zone itself is not stored** — it is resolved from `school_code` when rendering (§7.5). `attendance_date` is the school-local calendar date. The day window (§8.5) is evaluated in school-local time.

> **Operational note:** because the zone is derived, **changing a school's timezone setting is a data-migration event** — it re-renders the local time of historical rows. Treat it as a careful, reviewed change rather than a routine settings edit.

### 10.2 Recompute
Approval/apply triggers the existing overtime recompute for the affected `(staff, date)`. Bulk approve recomputes each affected day (batch acceptable).

### 10.3 Concurrency / idempotency
Partial-unique on PENDING prevents duplicate raises. Approve / bulk approve are idempotent and snapshot-based; already-decided items are **skipped**, not errored. An edit that races an approval loses: once `status = APPROVED`, the edit is rejected with `409`.

### 10.4 Audit
Keep `requested_sign_out_time` and `approved_sign_out_time` side by side, plus `raised_by_code`, `approval_by_code`, `approval_at`, `reason` and `approval_note` — so the full trail (asked → applied, by whom, and whether the approver was the raiser) is reconstructable even after later edits to the attendance row (§7.4). The denormalized `regularization_code` on the attendance row links back. The table has no soft delete, so nothing in the trail is ever removed; `updated_at` / `updated_by_code` record that a pending request was edited (§9.4). Actor **names** are resolved at read time, not stored (§7.5).

### 10.5 Notifications (expected, not blocking v1)
- On raise → notify school admins ("N requests need approval").
- On approve → notify the staff.

---

## 11. Why a separate table (not columns on `staff_attendance_record`)

| Reason | Detail |
|---|---|
| **Future kinds have no row to hang columns on** | Missed **sign-in** / **full-day** requests would exist *before* any attendance row (apply would *create* it). Columns-on-attendance can never model a request for a record that doesn't exist yet — so even though today's scope always has a target row, the workflow belongs in its own table. |
| **Lifecycle + history** | requested-vs-approved time, who asked, who approved, reason, approval note, edits — these are *history*, natural as rows. Columns hold only the latest state and lose the trail. |
| **Query shape** | admin inbox = "all PENDING for school", indexed + paginated on a small table; vs. filtering the large, hot attendance table by a sparse status column. |
| **Sparsity** | ~99% of attendance rows never regularize; a dozen mostly-NULL workflow columns would bloat the core, hot table. |
| **Blast radius** | attendance stays the clean source-of-truth for punches; the workflow (SLA/escalation/bulk) evolves without touching it. |

**Hybrid we adopt:** workflow in `staff_attendance_regularization`, plus 2 denormalized read-optimizers on the attendance row (`signed_out_method = REGULARIZED` and `regularization_code`) so attendance screens show "regularized" without a join.

*Columns-on-attendance would only win if regularization were a trivial 1:1 flag with no approval, no history, and only ever fixing an existing row — which it isn't.*

---

## 12. Resolved decisions

| # | Decision | Resolution |
|---|---|---|
| 1 | Provisional accounting | **Exclude the session — 0 counted until approved.** The scheduler writes `total_worked_minutes = 0`, and overtime skips any day whose last session is still `signed_out_method = SYSTEM`. |
| 2 | Confirm auto-approval | **Staff: no** — every staff-raised request is PENDING so admins are aware, and `reason` is always required. **Admin-raised: yes** — auto-approved + applied by the backend (§8.2b). |
| 3 | Gate vs. sign-in | **Raising is mandatory before the next sign-in, for staff *and* admin-on-behalf.** A PENDING request unblocks sign-in. Consequence: no multi-day backlog can form, so the multi-day workflow is **dropped**. |
| 4 | Reject / cancel | **Both removed.** Admin approves or leaves pending; a wrong request is **edited while pending** (§9.4). No REJECTED and no CANCELLED enum — `status` has exactly two values. |
| 5 | Overnight window | **From school schedule settings**; default cap **before 19:00** local when settings absent. Applies to raise, edit and modified approval. |
| 6 | Bulk approve scope | **Multi-select, then approve selected.** `codes` required; no "approve all pending". Remaining/tricky handled individually. |

---

## 13. Client mapping (reference)

- `MissedSignout` → §9.1 open-session item.
- `RegularizationRequest` (`RegStatus` = pending/approved; **no** cancelled, **no** `RegType`, **no** `requestedSignInAt`) → §7.2 row.
- Single sheet `reg_resolve_sheet` → §9.2 (one submit: actual time + reason). `byAdmin: true` + `staffName` switches it to admin-raise copy ("Sign-out missing", "approved automatically", **Save sign-out**) for §8.2b. There is **no** multi-day sheet — the §5.1 invariant makes it unnecessary. Re-opening the same sheet on a request that already exists should call **PATCH** (§9.4), not POST.
- Admin decision sheet `reg_decision_sheet` → §9.6 (approve + optional modify + note; **no reject**).
- Admin inbox multi-select + "Approve selected (N)" → §9.7.
- Bulk sign-in gate sheet `reg_bulk_signin_gate_sheet` (+ row `reg_staff_time_row`) → §9.1b + §9.2b. Lists the blocked staff, one tap closes all, `Skip` lets the unblocked staff sign in. Returns `List<RegBulkGateItem>`.
- **Client cleanup required by this revision:** remove the cancel action from the staff list, drop `confirmedSoftTime` / `confirmedSuggestedTime` from the submit payload, and rename `requestedSignOutAt` → `requestedSignOutTime` and `signOutAt` → `signOutTime` on the approve call.

`attendance_v2` already consumes `sign-in`/`sign-out`, `staff-attendance-records/daily/{code}` (PATCH), `staff-overtime-records/{profile,calculate}` — regularization plugs into the same rows + recompute path.
