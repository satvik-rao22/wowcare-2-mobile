# Staff Attendance & Overtime — Product Proposal & Technical Design

| | |
|---|---|
| **Status** | Proposal — for founder & leadership review |
| **Author** | Tech Lead |
| **Date** | 2026-06-12 |
| **Scope** | Full-stack: Backend (Attendance MS), Web Admin (vg-wowcare-frontend), Mobile (wowcare2-mobile) |
| **Document structure** | **Part A** — what we should build and why (product recommendations, with impact). **Part B** — how we will build it (technical design). |

---

# PART A — Building an Industry-Best Attendance & Payroll Product

## A1. The Opportunity

Today our product *records* staff attendance. The industry leaders in workforce management (Keka, Zoho People, Workday, Deputy, ADP) do something more valuable: they turn attendance into **trusted money** — numbers that staff believe, admins can pay against, and auditors can verify.

That trust gap is exactly where we can stand out. Every childcare organization runs the same painful monthly ritual: someone exports attendance, fixes the missing punches by memory, computes overtime in a spreadsheet, and hopes nobody disputes it. **If our product produces payroll-grade numbers automatically, we stop being an attendance tracker and become the system the organization cannot run without.** That is the difference between a feature and a moat.

The recommendations below are proposals, not faits accomplis — each one states its impact so leadership can weigh, adjust, or reject it. But together they form a coherent bet: **correctness as the product.**

## A2. Where We Stand Today — and What It Costs Us

| Gap | What happens today | What it costs us |
|---|---|---|
| **Pre-computed aggregates via schedulers** | Nightly jobs calculate daily hours and store them in the DB. | Ongoing server cost and job-maintenance effort; **stale numbers** whenever a record is edited after the job runs; two sources of truth that can disagree — the worst property a payroll system can have. |
| **Silent fake sign-outs** | Forgot to sign out? The system invents a sign-out at school end time and the record looks real. | Staff who stayed late **lose real overtime money** (school ends 2:00 PM, staff stayed till 3:30 — that 1.5 hours vanishes). The moment one staff member catches this, trust in every number we show collapses. |
| **No correction workflow** | Missed punches can only be fixed by an admin manually editing records — if they even know. | Admins have **zero visibility** into who missed punches; staff have no self-service path; corrections are untracked. Industry-standard "attendance regularization" simply doesn't exist in our product. |
| **No payout model** | Hours exist; money doesn't. No rates, no multipliers, no estimated payout. | The most valuable question — *"what do I get paid?"* / *"what do I owe?"* — is answered outside our product, in spreadsheets. We hand our stickiest use-case to Excel. |

## A3. Recommendations

Each recommendation lists **what**, **why it's the right standard**, and **impact**. R1–R6 form the core proposal; R7–R10 are the differentiators that come nearly free once the core exists.

---

### R1 — Compute everything on-demand from raw records. Delete the schedulers.

**What:** Raw sign-in/sign-out sessions become the single source of truth. Daily totals, monthly totals, overtime, and payout are computed at read time by one deterministic calculation engine on the backend, with smart caching. Stored daily aggregates and the nightly jobs that produce them are decommissioned.

**Why this is the right standard:** Derived data should be derived, not stored. Every serious financial system computes views from an immutable event log — because the moment you store a copy of a calculation, you sign up for keeping it in sync forever.

**Impact:**
- **Server cost ↓** — we stop computing (every staff × every school × every night) whether anyone looks or not, and compute only what is actually read. A full month for one staff is ~31 days × a handful of sessions — sub-millisecond math.
- **Dev effort ↓** — an entire failure class disappears: missed runs, partial runs, replay logic, aggregate-vs-record reconciliation.
- **Correctness ↑** — an edit at 11 PM is reflected instantly, everywhere, always. Stale numbers become structurally impossible.

---

### R2 — Stop fabricating sign-outs. Make missing punches honest and visible.

**What:** When staff forget to sign out, the school chooses (per-school setting) between two honest behaviors: **auto-close** at school end time but visibly flagged as system-generated, or **leave open** and route into a correction flow. Either way, the record never pretends to be a real punch, and every missing punch is counted and surfaced to the admin.

**Why this is the right standard:** A payroll system must never silently invent data. Flagged-provisional records are how Deputy, Workday, and every serious time-and-attendance product handle missed punches.

**Impact:**
- **Staff stop losing earned overtime** — the late-emergency-stay scenario is now recoverable instead of silently erased.
- **Admins gain a control they've never had:** a live count of unresolved punches per staff, per month — before payroll, not after the dispute.
- **Trust** — every number on screen is either real or visibly provisional. Nothing in between.

---

### R3 — Attendance regularization workflow (request → approve), with a proper approval hierarchy.

**What:** Staff who missed a punch raise a regularization request ("I actually left at 3:30 PM, here's why") from a *Needs Attention* prompt in the app. The request routes to their approval manager; managers get an approvals inbox with one-tap approve/reject. Every staff member has an assigned approver; school admins are approved by the org admin; the topmost admin is self-approved but still audited. Approved corrections update the record and recalculate instantly.

**Why this is the right standard:** This is *the* canonical HR workflow — table stakes in Keka, Zoho People, greytHR, Darwinbox. Buyers coming from any of those products will ask where it is.

**Impact:**
- **Closes our biggest feature gap** vs. established HR products — removes a recurring objection in sales conversations.
- **Managers gain awareness** of who misses punches and when people actually leave — today this knowledge doesn't exist anywhere.
- **Self-service ↓ admin workload** — corrections flow bottom-up with context attached, instead of admins hunting and guessing.

---

### R4 — Show every staff member their estimated payout, live.

**What:** A staff-facing *My Attendance & Payout* view: attended days, regular vs. overtime hours, and an estimated payout for the month (salary + overtime at the configured multiplier − any provisional deduction), updating in real time as the month progresses.

**Why this is the right standard:** Pay transparency is the single strongest trust lever in workforce products. People check this screen daily — it becomes the habit loop that keeps our app on every staff member's home screen.

**Impact:**
- **Daily engagement** from every staff user, not just admins — attendance compliance improves because staff see exactly what each punch is worth.
- **Payroll disputes ↓** — staff who watched their number all month don't contest it on pay day.
- **Differentiation** — most childcare-management competitors don't show staff their money. We would.

---

### R5 — Payroll finalization: locked periods and immutable snapshots.

**What:** Before paying, the admin reviews each staff-month and resolves every flagged item with an explicit choice: ask staff to regularize, bulk-default missing sign-outs to school end time, approve full pay regardless of shortfall, or apply a deduction at a configurable rate (1.0× or 0.5× hourly). Then they **finalize the month**: an immutable snapshot of every number and every decision is stored, the period locks, and historical records can no longer drift away from money already paid. Reopening a period is possible — but explicit, senior-only, and audited.

**Why this is the right standard:** Numbers that money was paid against must be frozen. Period locking is non-negotiable in every payroll system on the market; a system without it will eventually show a "history" that contradicts a bank transfer.

**Impact:**
- **"Automate payout" becomes safe** — this is the mechanism that turns estimated numbers into payable numbers.
- **The system never decides money silently** — all four payday scenarios are explicit, recorded admin choices.
- **Audit-readiness** — any payout, any month, fully reconstructable: which records, which rates, which rules, who decided what.

---

### R6 — Per-location configuration: multipliers, grace rules, deduction policy.

**What:** Every money-relevant rule is a per-school setting with sensible defaults: overtime multiplier (1.5× default — varies by region and regulation), daily regular hours (school default + per-staff override for part-timers), grace thresholds and rounding (so 3 stray minutes never trigger payroll changes), deduction factor, and missing-punch mode (R2). All settings are **effective-dated** — changing a rule mid-month never rewrites the past.

**Why this is the right standard:** Labor rules genuinely differ by location. Hard-coding any of them caps our market at one geography.

**Impact:**
- **Sell anywhere** — new regions are a configuration exercise, not an engineering project.
- **Correctness across time** — a multiplier change on June 15 computes June 1–14 with the old rate, automatically and provably.

---

### R7 — Full audit trail on every attendance mutation. *(near-free with R1–R5)*

Every create, edit, delete, system-close, and regularization writes an append-only audit entry (who, what, before, after, when). **Impact:** disputes resolve with evidence instead of arguments; enterprise and compliance-sensitive buyers require this; deletion mistakes become recoverable.

### R8 — Geofence sign-out nudges: prevent missed punches instead of correcting them. *(future, mobile)*

We already track geofence events for sign-in. The phone knows when staff leave campus — "You left Wise Owl Academy at 3:32 PM. Sign out?" **Impact:** attacks the root cause of the missed-punch problem; turns R3's correction volume into a shrinking number; a visibly smart, demo-able differentiator.

### R9 — Anomaly surfacing for admins. *(future, cheap once R1 exists)*

The calculation engine sees everything, so flagging the weird stuff is nearly free: impossible durations (>16h days), overtime spikes vs. a staff member's own baseline, chronic missed punches. **Impact:** catches both honest mistakes and time-theft before payday; positions the product as actively guarding the customer's money.

### R10 — Compliance guardrails and payslip export. *(future)*

Configurable max daily/weekly hour warnings (labor-law dependent), monthly payslip PDF for staff, and payroll-provider export formats. **Impact:** completes the path from punch to payslip entirely inside our product.

## A4. What This Adds Up To

| Without this proposal | With it |
|---|---|
| Attendance tracker with numbers people double-check in Excel | The system of record an organization pays salaries from |
| Staff discover payroll errors after payday | Staff watch their verified payout build up daily |
| Admins chase missing punches by memory | One screen: every unresolved item, every explicit decision, then lock |
| Server burns money computing reports nobody reads | Compute on read, cache, done |

**Ask:** approve the direction (R1–R6 core, R7 included, R8–R10 roadmap), adjust any default parameter in §B2 — every one of them is a knob, not a commandment — and we proceed with the phased, feature-flagged rollout in §B10, which keeps the old pipeline intact until the new engine has proven itself on real data.

---
---

# PART B — Technical Design

## 1. Problem Statement

Staff sign in and out multiple times a day (arrival, breaks, classroom transfers, departure). From these raw sessions the product must answer, correctly and cheaply:

1. **Staff:** "How many hours did I work, how much overtime, and what is my estimated payout this month?"
2. **Admin:** "What does payroll look like for all staff this month, and can I trust these numbers enough to automate payout?"

### 1.1 Problems with the current implementation

| # | Problem | Impact |
|---|---------|--------|
| P1 | Daily attendance aggregates (regular/OT hours) are **precomputed by schedulers and stored in the DB**. | Server cost, dev effort maintaining jobs, stale data when records are edited/deleted after the job runs, double source of truth (raw records vs aggregates can disagree). |
| P2 | When staff forget to sign out, the system **silently auto-signs them out at school end time**. | Staff who stayed late (e.g., school ends 2:00 PM, staff left 3:30 PM) lose real overtime. The record looks legitimate — nobody knows it was system-generated. |
| P3 | **No regularization workflow.** Missed punches can only be fixed by an admin manually editing the record. | Admins have no visibility into who is missing punches; staff have no self-service path; corrections are untracked and unauditable. |
| P4 | **No payout model.** Overtime hours exist but there is no rate configuration, multiplier, or estimated-payout view. | Payroll is computed outside the product. |

### 1.2 Goals

- **Correctness:** payout numbers derived from raw records via one deterministic, versioned formula. No silent data fabrication (P2).
- **Scalability:** computation cost grows with reads actually performed, not with (staff × days) every night. No schedulers (P1).
- **Stability:** edits, deletes, and regularizations cannot corrupt finalized payroll; everything is audited; rollout is feature-flagged.

### 1.3 Non-goals (v1)

- Actual money transfer / bank integration. We produce **estimated payout + payroll export**; disbursement stays external.
- Student attendance (unchanged).
- Shift-based expected hours from the Scheduling module (deferred — see R8/PI-7).
- Multi-level approval chains (v1 is single approver per staff; see §7).

---

## 2. Proposed Design Parameters

> These map Part A's recommendations to concrete defaults. **Every value here is adjustable at review** — the architecture treats each as configuration, not a constant.

| # | Parameter | Proposed choice |
|---|----------|--------|
| D1 | Overtime basis | **Daily threshold.** OT for a day = worked time beyond that day's regular hours. Monthly OT = Σ daily OT. |
| D2 | Regular hours source | **School default + per-staff override** (e.g., school default 8h/day; a part-timer can be set to 4h/day). |
| D3 | Calculation location | **Backend, computed on-demand at read time** from raw sign-in/out records, with caching. No stored daily aggregates, no schedulers. One source of truth for mobile, web, and payroll export. |
| D4 | Hourly rate derivation | **monthlySalary ÷ (workingDaysInMonth × dailyRegularHours)**. Recomputed per month from the school working-day calendar. |
| D5 | OT multiplier | Per-school setting, default **1.5×** hourly rate (varies by location/regulation). |
| D6 | Missing sign-out | **School-level config:** `AUTO_CLOSE` (auto sign-out at school end, but the record is flagged `SYSTEM_CLOSED`) or `APPROVAL_BASED` (session stays open, surfaces in "Needs Attention", staff raises regularization). In both modes the missing-punch count is visible to admin. |
| D7 | Under-time deduction | Admin choice at payroll time per staff (or bulk): pay full regular salary, or deduct shortfall at a configurable rate (**1.0× or 0.5× hourly rate**, per-school setting). |
| D8 | Grace & rounding | **Configurable per school** with defaults: OT counted only beyond a minimum threshold/day, rounded to a unit (defaults below). Same knobs for under-time. |
| D9 | Regularization approval | Every staff has one **approval manager**. School admin's requests go to the org admin (if the org has one). The topmost admin needs no regularization (self-approved). |

---

## 3. High-Level Architecture

```
                 ┌────────────────────────────────────────────────┐
                 │              Attendance Microservice            │
                 │                                                  │
 Mobile (Flutter)│  ┌──────────────┐     ┌─────────────────────┐  │
 ───────────────▶│  │ Raw Records  │────▶│  Calculation Engine  │  │
                 │  │ (sessions,   │     │  (pure function,     │  │
 Web Admin       │  │  immutable   │     │   versioned spec,    │  │
 ───────────────▶│  │  event log + │     │   computed on read)  │  │
                 │  │  audit)      │     └──────────┬──────────┘  │
                 │  └──────────────┘                │              │
                 │  ┌──────────────┐     ┌──────────▼──────────┐  │
                 │  │ Config       │     │  Read-through Cache  │  │
                 │  │ (school +    │     │  (per staff-month,   │  │
                 │  │  staff,      │     │   invalidated on     │  │
                 │  │  effective-  │     │   write)             │  │
                 │  │  dated)      │     └──────────┬──────────┘  │
                 │  └──────────────┘     ┌──────────▼──────────┐  │
                 │  ┌──────────────┐     │  Payroll Snapshots   │  │
                 │  │ Regulariza-  │     │  (immutable, created │  │
                 │  │ tion requests│     │   only at finalize)  │  │
                 │  └──────────────┘     └─────────────────────┘  │
                 └────────────────────────────────────────────────┘
```

**Core principle:** raw attendance sessions are the **single source of truth**. Everything else (daily totals, monthly totals, OT, payout) is a **derived, reproducible view** — computed on demand, cached, and only ever *persisted* as an immutable snapshot at payroll finalization.

### 3.1 Why on-demand beats schedulers here

- **Correctness:** an edit/delete/regularization at 11 PM is reflected instantly; a nightly job would serve stale aggregates until the next run, and needs reconciliation logic for retro-edits.
- **Cost:** schedulers compute (all staff × all schools × every day) whether anyone looks or not. On-demand computes only what is read; a staff-month is ≤ ~31 days × a handful of sessions — trivial CPU.
- **Simplicity:** deleting the job framework removes a whole failure class (missed runs, partial runs, replays).

### 3.2 Scale sanity check

Worst realistic read: admin opens monthly payroll for a school with 200 staff → 200 staff-months → ~200 × 31 days × ~6 sessions ≈ 37k session rows, one indexed range query per school, pure-function math in memory. Single-digit milliseconds of compute. With the staff-month cache, repeat reads don't even touch the records table.

---

## 4. Data Model (Backend)

> Field names are illustrative; align with existing Attendance MS conventions. All timestamps stored in **UTC** with the school's IANA timezone applied at calculation time.

### 4.1 `staff_attendance_session` (exists today — amended)

The raw record. One row per sign-in/sign-out pair.

```
code                  PK
staff_code            FK, indexed
school_code           FK, indexed
classroom_code
attendance_date       DATE (school-local), indexed   -- composite idx (school_code, attendance_date), (staff_code, attendance_date)
signed_in_at          TIMESTAMPTZ
signed_in_by          staff_code
signed_in_method      GPS | QR | PIN | APP | WEB
signed_out_at         TIMESTAMPTZ NULL               -- NULL = open session
signed_out_by         staff_code NULL
signed_out_method     GPS | QR | PIN | APP | WEB | SYSTEM
close_type            NORMAL | SYSTEM_CLOSED | REGULARIZED | NULL(open)   -- NEW (fixes P2)
source_request_code   FK → regularization_request NULL                    -- NEW: which approval created/edited this
version               INT (optimistic locking)                            -- NEW
created_at / updated_at / deleted_at (soft delete)
```

**Changes from today:**
- `close_type` distinguishes a real punch-out from a system auto-close — the keystone of fixing P2. A `SYSTEM_CLOSED` session is *visibly provisional* everywhere.
- Soft delete + `staff_attendance_audit` (below) instead of hard delete.
- Open sessions (`signed_out_at IS NULL`) are now a legal persistent state when school config = `APPROVAL_BASED`.

### 4.2 `staff_attendance_audit` (new)

Append-only log: `(session_code, action: CREATE|EDIT|DELETE|SYSTEM_CLOSE|REGULARIZE, actor_code, before_json, after_json, at)`. Every mutation of a session writes here. Required for trust in payroll and for the edit/delete flows that already exist in both clients.

### 4.3 `school_attendance_payroll_settings` (new, **effective-dated**)

```
school_code                       FK
effective_from                    DATE        -- config changes never rewrite history
timezone                          IANA string
daily_regular_hours_default       e.g. 8.0
ot_multiplier                     e.g. 1.50
ot_min_daily_minutes              default 15   -- OT below this per day is ignored
ot_rounding_minutes               default 15   -- floor to unit
undertime_min_daily_minutes       default 15
undertime_rounding_minutes        default 15
undertime_deduction_factor        1.0 | 0.5    -- D7
missing_signout_mode              AUTO_CLOSE | APPROVAL_BASED   -- D6
auto_close_time                   school end time (used by AUTO_CLOSE and by admin bulk-default action)
working_days                      e.g. [MON..FRI]  -- for D4 workingDaysInMonth
```

**Effective-dating is non-negotiable for correctness:** when the multiplier changes from 1.5 → 1.6 on June 15, June 1–14 must still compute with 1.5. Every calculation resolves config **as-of the attendance date**, never "current config".

### 4.4 `staff_compensation` (new, **effective-dated**)

```
staff_code, effective_from
monthly_salary                    e.g. 10000
daily_regular_hours_override      NULL → use school default   (D2)
approval_manager_code             staff_code NULL → falls back per §7 hierarchy
```

Same effective-dating rule: a raise on June 15 applies a blended month (rate resolved per-day, see §5.4).

### 4.5 `attendance_regularization_request` (new)

```
code                    PK
staff_code              requester (or beneficiary if raised by manager on staff's behalf)
school_code
attendance_date
type                    MISSED_SIGN_OUT | MISSED_SIGN_IN | MISSED_FULL_DAY | TIME_CORRECTION
target_session_code     FK NULL (NULL for MISSED_FULL_DAY — creates a new session)
requested_sign_in_at    TIMESTAMPTZ NULL
requested_sign_out_at   TIMESTAMPTZ NULL
reason                  TEXT (required)
status                  PENDING | APPROVED | REJECTED | CANCELLED
approver_code           resolved at creation time (snapshot, so a manager change doesn't orphan requests)
decided_by / decided_at / decision_note
created_at / updated_at
```

Constraint: at most one `PENDING` request per `(staff_code, attendance_date, target_session_code)`.

### 4.6 `payroll_snapshot` (new, immutable)

Created **only** when admin finalizes a month (§6.4). Stores, per staff-month: all computed figures, the calc-spec version, the resolved config values, the set of session codes + their `updated_at` it was computed from, and per-staff admin decisions (D7 choices). Once a snapshot exists for (school, month), the period is **locked**: session mutations and regularizations for dates in that period are rejected unless the admin explicitly reopens the period (which voids the snapshot and is audited).

> **Why locking matters:** without it, an edit in July to a June record silently diverges from money already paid. Lock + explicit reopen + audit makes the divergence impossible or at least deliberate and visible.

---

## 5. Calculation Specification (the heart of the system)

The engine is a **pure, deterministic, versioned function**:

```
calcStaffMonth(sessions, absences, schoolSettings(asOfDate), staffComp(asOfDate), month) → StaffMonthSummary
```

No clock reads, no DB access inside — inputs in, numbers out. This makes it unit-testable with golden vectors (§11) and lets the spec version be stamped into payroll snapshots.

### 5.1 Step 1 — Per-day session normalization

For each staff and school-local `attendance_date`:

1. Collect non-deleted sessions for that date. Order by `signed_in_at`.
2. **Validate/repair overlaps:** if session N's sign-out > session N+1's sign-in (data corruption from manual edits), merge the overlap (count overlapped minutes once) and emit a `DATA_OVERLAP` warning on the day. Never double-count time.
3. **Worked minutes** = Σ (signed_out − signed_in) across sessions.
   **Break minutes** = gaps between consecutive sessions (first sign-in → last sign-out span − worked). Breaks are **unpaid by construction** — only signed-in time counts (matches current product behavior; the "Break Minutes" column in the web UI is exactly these gaps).
4. **Open / system-closed handling:**
   - Session with `close_type = SYSTEM_CLOSED` → its minutes count **up to the auto-close time only**, and the day is flagged `hasSystemClosure = true`.
   - Open session (`APPROVAL_BASED` mode) → contributes **0 confirmed minutes**; the day is flagged `hasOpenSession = true` and worked time is reported as *provisional* (UI shows "—, needs attention"), never silently estimated.
   - In both cases the day increments the month's `missingSignOutCount`.

### 5.2 Step 2 — Per-day classification

```
regularTarget = staffComp.daily_regular_hours_override ?? school.daily_regular_hours_default   (as-of that date)

rawOT        = max(0, worked − regularTarget)
otMinutes    = rawOT < ot_min_daily_minutes ? 0 : floorTo(rawOT, ot_rounding_minutes)

rawShort     = max(0, regularTarget − worked)          // only on expected working days, not absent-approved days
shortMinutes = rawShort < undertime_min_daily_minutes ? 0 : floorTo(rawShort, undertime_rounding_minutes)

regularMinutes = min(worked, regularTarget)
```

- A day with an **approved absence** (full-day) contributes nothing to OT/short and is not counted as a working day for that staff.
- Half-day absence: `regularTarget` halves for that day.
- A non-working day (per school `working_days`) with attendance: **all** worked minutes are OT (configurable later — see PI-6; v1 hard rule, called out for review).
- An **overnight session** (sign-out past midnight): minutes attribute to the **sign-in date** (one rule, applied consistently; matters for daily OT).

### 5.3 Step 3 — Monthly aggregation

```
attendedDays, absentDays, missingSignOutCount, openSessionCount
totalRegularMinutes  = Σ regularMinutes
totalOTMinutes       = Σ otMinutes
totalShortMinutes    = Σ shortMinutes
isProvisional        = any open sessions OR pending regularizations in the month
```

`isProvisional` is the flag that gates payroll finalization (§6.4).

### 5.4 Step 4 — Payout estimation

```
workingDaysInMonth = count of school working_days in calendar month        (D4)

For each day d:
  hourlyRate(d)    = monthlySalary(asOf d) ÷ (workingDaysInMonth × dailyRegularHours(asOf d))

otPay        = Σ_d otMinutes(d)/60    × hourlyRate(d) × ot_multiplier(asOf d)
deduction    = Σ_d shortMinutes(d)/60 × hourlyRate(d) × undertime_deduction_factor     // only if admin chooses to deduct (D7)

estimatedPayout = monthlySalaryProrated + otPay − appliedDeduction
```

Per-day rate resolution makes mid-month salary or config changes correct automatically. Currency math in integer minor units (paise/cents), round half-up at final display only.

### 5.5 Admin payroll decisions (D7 — covering every payday scenario)

For each staff-month at payroll time, for the `totalShortMinutes` and `missingSignOutCount`, the admin can:

| Action | Effect |
|--------|--------|
| **Request regularization** | Sends nudge to staff (bulk or individual); month stays provisional until resolved. |
| **Default missing sign-outs** | Bulk-converts open/system-closed days to sign-out = `auto_close_time` (writes audited `REGULARIZE` edits, `close_type = REGULARIZED`, actor = admin). |
| **Approve full pay** | `appliedDeduction = 0` for this staff regardless of `shortMinutes`. Recorded in snapshot. |
| **Apply deduction** | `appliedDeduction = deduction` at the school's `undertime_deduction_factor` (1.0× or 0.5×). Recorded in snapshot. |

All four are explicit, audited choices stored in the `payroll_snapshot` — the system never decides money silently.

### 5.6 Spec versioning

The formula above is `CALC_SPEC_V1`. Any change to the rules ships as `V2` behind a date or school flag; old snapshots remain reproducible because they record their spec version. **Never** change calculation behavior in place.

---

## 6. API Design

All under the Attendance MS (`/api/v1/...`), consistent with existing route style in `lib/core/util/api_paths.dart`.

### 6.1 Computed views (replace stored-aggregate reads)

```
GET /staff-attendance/summary/monthly
    ?staffCode=&month=2026-06                     → StaffMonthSummary (all of §5.3 + §5.4 + per-day breakdown)
GET /staff-attendance/summary/monthly/school
    ?schoolCode=&month=&page=&size=               → list of StaffMonthSummary (admin payroll grid)
GET /staff-attendance/needs-attention
    ?schoolCode=&fromDate=&toDate=                → open sessions, system-closed days, pending regularizations
```

The existing `view/daily`, `view/custom`, `profile` endpoints stay, but their `attendedHours/attendedMinutes/overtime` fields are now produced by the same engine at read time (not read from aggregate tables).

**Caching:** read-through cache keyed `(staffCode, month, calcSpecVersion)`. Invalidate on: session create/edit/delete, regularization decision, compensation or school-settings change touching the period. TTL as backstop (e.g., 1h). Current month is the hot key and also the most-mutated — invalidation-on-write is what keeps it correct.

### 6.2 Regularization

```
POST   /attendance-regularizations                          create (staff self-service or manager on behalf)
GET    /attendance-regularizations?role=requester|approver&status=&page=
PUT    /attendance-regularizations/{code}/approve           body: optional adjusted times + note
PUT    /attendance-regularizations/{code}/reject            body: note (required)
PUT    /attendance-regularizations/{code}/cancel            requester only, while PENDING
```

Approve = transactional: update/create the target session (`close_type = REGULARIZED`, `source_request_code` set), write audit, invalidate cache, notify requester. Approver may adjust the requested time before approving (request stores both asked and granted).

### 6.3 Configuration

```
GET/PUT /schools/{schoolCode}/attendance-payroll-settings    (creates new effective_from row on change)
GET/PUT /staff/{staffCode}/compensation                      (effective-dated, school-admin+ only; salary fields RBAC-restricted)
PUT     /staff/{staffCode}/approval-manager
```

### 6.4 Payroll finalization

```
POST /payroll/snapshots          {schoolCode, month, perStaffDecisions[]}   → 409 if any staff-month isProvisional and unresolved
GET  /payroll/snapshots?schoolCode=&month=
POST /payroll/snapshots/{code}/reopen     (org-admin only, audited, voids snapshot)
GET  /payroll/snapshots/{code}/export     CSV/XLSX payroll export
```

### 6.5 Auto-close job — the one scheduler we keep

`AUTO_CLOSE` mode still needs a daily server-side close at `auto_close_time`. This is the **only** scheduled task that remains, and it's an *event writer* (closes open sessions with `close_type = SYSTEM_CLOSED`), not a *calculator*. In `APPROVAL_BASED` mode it only emits "you forgot to sign out" notifications. Idempotent and safe to re-run.

---

## 7. Regularization Workflow & Approval Hierarchy

### 7.1 Approver resolution (D9)

```
resolveApprover(staff):
  1. staff.approval_manager_code if set and active
  2. else school admin of staff's school
  3. for a school admin → organization admin (if org has one)
  4. for the topmost admin (org admin, or school admin when no org admin) → SELF_APPROVED:
     their regularizations apply immediately but still write a request row (status=APPROVED,
     decided_by=self) + audit, so nothing bypasses the trail.
```

Approver is **snapshotted onto the request** at creation; manager changes don't orphan pending requests. If an approver is deactivated, pending requests re-route up the chain (background-safe, on next read).

### 7.2 State machine

```
            ┌──────────┐  approve   ┌──────────┐
  create →  │ PENDING  │──────────▶│ APPROVED │→ session updated, cache invalidated
            │          │  reject    ├──────────┤
            │          │──────────▶│ REJECTED │
            │          │  cancel    ├──────────┤
            └──────────┘──────────▶│ CANCELLED│
                                   └──────────┘
```

Terminal states are immutable; a rejected request can be re-raised as a new one. No request may target a date inside a finalized payroll period (§4.6).

### 7.3 Notifications

| Event | Recipient | Channel |
|---|---|---|
| Forgot sign-out (end of day) | Staff | Push + in-app |
| Request created | Approver | Push + in-app badge |
| Pending > 48h | Approver (reminder) | Push |
| Approved / rejected | Requester | Push + in-app |
| Payroll week: unresolved missing punches | Admin digest | In-app |

---

## 8. Mobile App Changes (this repo)

Follows the existing clean-architecture layout (`lib/{domain,data,presentation}/features/attendance/`).

### 8.1 New domain entities

- `StaffMonthSummary` (mirrors §5.3/§5.4: regular/OT/short minutes, missing-punch counts, `isProvisional`, `estimatedPayout`, per-day breakdown rows)
- `RegularizationRequest` (+ status/type enums)
- `AttendancePayrollSettings`

### 8.2 New use-cases & repositories

`GetStaffMonthlySummaryUseCase`, `GetNeedsAttentionUseCase`, `CreateRegularizationUseCase`, `GetRegularizationsUseCase` (requester + approver views), `DecideRegularizationUseCase`, `CancelRegularizationUseCase` — added to `AttendanceRepository` + remote datasource + DI registrations, same pattern as the existing ~30 use-cases.

### 8.3 Screens

| Screen | Notes |
|---|---|
| **My Attendance & Payout** (staff) | Month picker; cards for Attended Days / Attended Time (regular vs OT, matching the web design) / Absent Days; **Estimated Payout** card (salary + OT − provisional deduction, with "provisional" banner when `isProvisional`); day list with per-day OT and `SYSTEM_CLOSED`/open badges. Salary figures shown only to self + admins (reuse `ROLE_BASED_ACCESS_SPEC.md` gates). |
| **Needs Attention** section | On staff home/attendance: days with open or system-closed sessions → one-tap "Regularize" prefilled with date + auto-close time. |
| **Regularization form** | Type, date, requested times, mandatory reason. |
| **Approvals inbox** (managers/admins) | Pending list with requested vs current times diff; approve (with optional time adjustment) / reject with note. Badge count. |
| **Staff attendance profile** (existing, `staff_attendance_profile.dart`) | Add OT split to the attended-time card; show `close_type` badge per row; "Regularize" action in the row's ⋯ menu alongside existing Edit/Delete. |

### 8.4 Existing edit/delete flow

Unchanged UX, but the backend now: writes audit rows, bumps `version` (optimistic lock — stale edit returns 409, UI prompts refresh), rejects mutations in finalized periods (UI surfaces "period locked" message), and invalidates the summary cache.

### 8.5 Offline/caching (Isar)

Cache `StaffMonthSummary` per month via the existing `CacheManager`, TTL-based, replaced on fetch. **Do not** compute payroll math client-side — clients render server numbers only (one source of truth, D3). Display-only formatting stays in `attendance_attended_duration.dart`.

## 9. Web Admin Changes (vg-wowcare-frontend — high level)

- Staff attendance detail (the screenshots): Summarised/Separate views read the new monthly-summary endpoint; add `SYSTEM_CLOSED`/open badges and per-row regularization status.
- **Payroll page (new):** school + month → staff grid (regular, OT, short, missing punches, estimated payout, provisional flag) → per-staff/bulk D7 actions → **Finalize month** → snapshot + export.
- **Settings page (new):** school attendance-payroll settings (§4.3) with effective-from date picker; staff compensation + approval manager on the staff profile.
- Approvals inbox for admins (same API as mobile).

---

## 10. Migration & Rollout Plan

Feature flag: `attendance_otc_v2` (per school).

| Phase | Work | Exit criteria |
|---|---|---|
| **0. Spec freeze** | Golden test vectors (§11) reviewed by Product against real payroll examples (incl. the Spandana Marri June data from the dashboard). | Signed-off vector file. |
| **1. Backend dual-read** | Ship engine + new endpoints; old scheduler keeps running. Shadow-compare engine output vs stored aggregates for N schools; log mismatches. | < 0.1% mismatch, every mismatch explained (most will be *engine right, aggregate stale*). |
| **2. Config & backfill** | Create settings rows per school (timezone, end time, defaults), compensation rows (salary entry by admins), backfill `close_type = SYSTEM_CLOSED` for historical auto-closed records (identifiable by sign-out == school end time ∧ signed_out_by = system). | All active schools configured. |
| **3. Cutover reads** | Flip flagged schools' read paths (mobile + web) to computed endpoints. Old aggregates untouched but unread. | 2 clean weeks incl. one month-end. |
| **4. Regularization + payroll** | Enable workflow + payroll page per school. | First finalized month with snapshot per pilot school. |
| **5. Decommission** | Stop scheduler (except auto-close, §6.5), archive aggregate tables (read-only, retained ≥ 1 payroll year), delete job code. | Server cost reduction measured. |

Rollback at any phase = flip flag back to old read path (old pipeline still intact until phase 5).

---

## 11. Testing Strategy

- **Golden vectors (most important):** a versioned fixture file of `(sessions, config, expected StaffMonthSummary)` cases covering every edge case in §13. Backend engine must pass 100%. These vectors *are* the spec; Product signs them off, and any future `V2` change starts by writing new vectors.
- **Property tests:** worked = regular + OT − never negative; Σ days = month totals; merging overlap never increases total minutes; rate × time monotonicity.
- **Contract tests:** mobile/web models vs API JSON (prevents the silent-field-rename class of bug).
- **Concurrency tests:** simultaneous edit + approve on the same session (optimistic lock); finalize vs concurrent edit (lock wins).
- **E2E happy paths:** forgot-sign-out → notification → regularize → approve → summary updates → finalize → export contains corrected OT.

---

## 12. Recommendation Traceability

| Part A | Delivered by | Status |
|---|---|---|
| R1 Kill schedulers; compute on-demand | §3, §6.1 | In scope |
| R2 Honest missing-punch handling | §4.1 `close_type`, §5.1, §6.5 | In scope |
| R3 Regularization workflow + hierarchy | §4.5, §6.2, §7 | In scope |
| R4 Staff-visible estimated payout | §5.4, §8.3 | In scope |
| R5 Payroll lock + snapshots + payday decisions | §4.6, §5.5, §6.4 | In scope |
| R6 Per-location, effective-dated config | §4.3, §4.4, §6.3 | In scope |
| R7 Full audit trail | §4.2 | In scope |
| R8 Geofence sign-out nudges | — | Roadmap (PI-8) |
| R9 Anomaly surfacing | — | Roadmap (PI-10) |
| R10 Compliance guardrails + payslips | — | Roadmap (PI-9/11) |

Roadmap items kept warm in the design: PI-6 weekend/holiday OT premium (config slot exists in §4.3), PI-7 expected hours from Scheduling module (replaces D2 source, engine unchanged).

---

## 13. Edge Cases & Correctness Checklist

| Case | Handling |
|---|---|
| Multiple sessions/day | Sum sessions; gaps = unpaid break (§5.1). |
| Overlapping sessions (bad edits) | Merge, count once, warn (§5.1). |
| Missing sign-out | Per school mode; never silently counted as full real time (§5.1, D6). |
| Forgot sign-in (raised later) | `MISSED_SIGN_IN` / `MISSED_FULL_DAY` regularization creates/edits session on approval. |
| Overnight shift | Attribute to sign-in date (§5.2). |
| Timezone / DST | Store UTC; compute in school IANA timezone as-of date; `attendance_date` is school-local. |
| Mid-month salary or config change | Effective-dated rows + per-day resolution (§4.3, §5.4). |
| Edit/delete after payroll finalize | Rejected; requires audited period reopen (§4.6). |
| Concurrent edit vs approval | Optimistic `version`; loser gets 409. |
| Approver left / changed | Approver snapshotted on request; re-route on deactivation (§7.1). |
| Half-day absence | Halved `regularTarget` (§5.2). |
| Attendance on non-working day | All OT (v1 rule — flag for Product review) (§5.2). |
| Clock drift / future timestamps | Server timestamps authoritative for live punches; manual times validated ≤ now + sane bounds. |
| Rounding | Integer minutes throughout; money in minor units; round at display (§5.4). |
| Cache staleness | Invalidate-on-write + TTL backstop (§6.1). |

---

## 14. Open Questions for Leadership

1. Non-working-day attendance = 100% OT (v1 rule, §5.2) — confirm with Product/locations, since some regions mandate 2×.
2. Should staff see the **rate** (₹/hr) or only the resulting amounts? (Privacy/HR preference per org.)
3. Payroll export format(s) the finance side actually consumes — CSV columns to be confirmed before §6.4 export is built.
4. Retention period for audit + snapshots (regulatory; assume ≥ 7 years until told otherwise).
5. Does any current school pay OT today via an external process we must reconcile against during phase 1 shadow-compare?
