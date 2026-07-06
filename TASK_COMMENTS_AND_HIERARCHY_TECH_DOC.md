# WowCare Tasks — Architecture & Implementation Guide

| | |
|---|---|
| **Version** | v3.1 — **Final.** v3.0 consolidated two adversarial review rounds; v3.1 replaces group assignment-targets with an explicit series roster (`task_assignee`) and human-in-the-loop turnover, per backend review. Implementation source of truth. |
| **System** | Task management for childcare schools: one-off and recurring tasks, multi-assignee with per-person tracking, comments, attachments with history, audit trail, calendar, reporting. |
| **Stack** | PostgreSQL → Spring Boot (Java) REST API → Flutter (mobile) + React (web). |
| **Platform alignment** | Follows the approved **Events/Calendar v4** patterns (series/occurrence split, transactional outbox → Kafka → `communication-service`), simplified where Tasks' profile differs: rolling window + idempotent job instead of a staged async pipeline, and an **explicit assignee roster** instead of audience-selector resolution. |
| **Status** | Greenfield backend; mobile currently local-only. No production data → no migration risk. |

---

## Table of Contents

**Part I — Understanding the system**
1. [The problem](#1-the-problem) · 2. [Goals and non-goals](#2-goals-and-non-goals) · 3. [Core concepts](#3-core-concepts) · 4. [Decisions at a glance](#4-decisions-at-a-glance) · 5. [How data flows](#5-how-data-flows)

**Part II — The data**
6. [Database design](#6-database-design) · 7. [Lifecycles and invariants](#7-lifecycles-and-invariants)

**Part III — The recurrence engine**
8. [Generation](#8-generation--materializewindow) · 9. [Activation](#9-activation--the-freeze-boundary) · 10. [Roster changes and staff deactivation](#10-roster-changes-and-staff-deactivation) · 11. [Projection](#11-projection--the-calendar-beyond-the-window) · 12. [Editing a series](#12-editing-a-series) · 13. [Pause, delete, restore](#13-pause-delete-restore) · 14. [Background jobs](#14-background-jobs)

**Part IV — Serving the product**
15. [Backend response design, screen by screen](#15-backend-response-design-screen-by-screen) · 16. [Calendar behavior](#16-calendar-behavior) · 17. [Reporting](#17-reporting) · 18. [Notifications](#18-notifications)

**Part V — Workflows end-to-end**
19. [Workflows](#19-workflows-end-to-end)

**Part VI — Quality attributes**
20. [Performance and scaling](#20-performance-and-scaling) · 21. [Security and multi-tenancy](#21-security-and-multi-tenancy) · 22. [RBAC and business rules](#22-rbac-and-business-rules) · 23. [Edge-case catalog](#23-edge-case-catalog)

**Part VII — Delivery**
24. [Clients and offline](#24-clients-and-offline) · 25. [Rollout plan](#25-rollout-plan) · 26. [Deferred capabilities](#26-deferred-capabilities) · 27. [Open product decisions](#27-open-product-decisions)

**Appendices** — [A. API reference](#appendix-a--api-reference) · [B. Worked example](#appendix-b--worked-example-with-dummy-data) · [C. New-developer orientation](#appendix-c--new-developer-orientation)

---

# Part I — Understanding the system

## 1. The problem

A childcare school runs on repeatable operational work: check classroom temperatures every weekday, sanitize equipment every Friday, recertify first-aid annually, plan one-off events. Today the mobile app models a task as a single flat record, which fails four real needs:

1. **Multi-assignee** — "assign to 10 people" created 10 unrelated copies with no shared identity, so an admin saw the same task 10 times and could never ask "how is *this task* going overall?"
2. **Recurrence** — "every weekday" was a label, not behavior: there was only one record, so Monday's completion overwrote the concept of Tuesday's work. Each recurrence needs its **own** status, comments, and attachments.
3. **Staff turnover** — when someone leaves, their pending work must be *surfaced for reassignment*, not silently orphaned (or silently rewired) — while their completed history stays intact.
4. **Compliance** — childcare is audited. "Who changed what, when" and "who actually did the 9 AM check on June 24" must be provable and immutable.

## 2. Goals and non-goals

**Goals:** admins see each task once with a live rollup and can drill into any person or date; staff see exactly their own work, one card per due date; recurrence with independently executed occurrences; turnover-safe assignment (deactivations surfaced for admin action); immutable history; full audit; offline-capable mobile; every list screen fast at any data size.

**Non-goals (v1):** Gantt/dependencies, custom fields, threaded comments/mentions, real-time co-editing, external calendar sync, arbitrary-depth sub-tasks. Each has a reserved path (§26) — none constrains the schema.

## 3. Core concepts

The whole design rests on separating four things that flat task models conflate:

| Concept | Table | One-line definition |
|---|---|---|
| **Series** | `task` | The definition + recurrence rule + lifecycle. *Never executed itself.* |
| **Assignee (roster)** | `task_assignee` | *Who should do it*: the series-level staff roster, explicit and admin-managed. Deactivations are surfaced for admin action — never silently rewired. |
| **Occurrence** | `task_occurrence` | One dated instance of the series — the executable unit. Per-day rollup, comments, attachments live here. |
| **Assignment** | `task_assignment` | One person's execution of one occurrence — status, effort, completion. The atom of work and of reporting. |

Supporting vocabulary: the **Window** is the rolling 60–90-day span of future occurrences kept materialized (it bounds storage *and* every write fan-out); **Activation** is the daily moment an occurrence's date arrives — its roster freezes and work begins; **Projection** is read-time expansion of the recurrence rule for calendar dates beyond the Window (display-only, no rows).

```
   TASK (series)  ── the "what": rule + lifecycle. Not executable.
     │
     ├── TASK_ASSIGNEE(s)  ── the "who": the series-level roster (explicit staff list)
     │
     ▼   engine materializes a rolling Window; the roster stamps assignments per occurrence
   TASK_OCCURRENCE  ── the "when": one dated instance. Rollup + per-day threads.
     │
     ▼
   TASK_ASSIGNMENT  ── the per-person FACT: status, effort, completion, private thread.
```

**Why four layers and not two:**
- A recurring series cannot carry "done" — only a specific date can. So execution state lives on occurrence/assignment, never the series.
- The roster lives on the **series**, so generation always knows who occurrence #47 belongs to. Turnover is **human-in-the-loop**: a deactivated staff member flags their roster row and notifies the admin, who reassigns or removes — completed history is never touched, and nothing is silently rewired.
- **A one-off task is a series that yields exactly one occurrence.** Same tables, one code path, no `if recurring` branching anywhere.

**Worked intuition:** "Daily temperature check, weekdays 9:00 — roster: Brian, Diego, Carla." The principal created **one rule with a roster**, not 260 tasks. When June 24 arrives, that day's occurrence exists with three assignments. Brian completes his; the occurrence rollup reads 1/3. If Diego is deactivated on the 26th, his roster row flips `INACTIVE`, his untouched future assignments are removed, and the admin is notified to reassign — the rule survives, future rollups read /2 until the admin acts, and Diego's completed June-24 work remains forever.

## 4. Decisions at a glance

Every load-bearing choice, with what was rejected and why — so no future debate re-litigates them blind:

| Decision | Rejected alternative | Why |
|---|---|---|
| Hybrid recurrence: rule + **windowed materialization** + read-time projection | *Pure virtual* (compute occurrences on read, like a naive calendar) | No row = nowhere to hang status/comments/attachments. Fatal for per-occurrence execution. |
| | *Full materialization to end date* | A daily task × 40 staff × 1 year = 14,600 rows up front, most never touched; unbounded fan-outs on every change. CMMS/ServiceNow generate on a forward window for exactly this reason. |
| **Explicit series-level roster** (`task_assignee`) with human-in-the-loop turnover | *(a)* Group targets (CLASSROOM/ROLE/DEPT) auto-resolved per occurrence; *(b)* no series-level "who" record at all | *(a)* deferred as YAGNI — silent auto-rewiring has its own failure mode (a new teacher inherits 15 tasks with zero context), and the upgrade is one added column (§26). *(b)* impossible — the generator must read *someone* when it creates occurrence #47 two months out. |
| **Idempotent scheduled job** builds the Window | Multi-stage async outbox pipeline (Events v4 style) | Generation is small (windowed) and not latency-sensitive; `ON CONFLICT DO NOTHING` gives crash-recovery for free. The pipeline solved Events' eager-full-series problem, which we don't have. |
| **Typed columns**; `JSONB` reserved for future flexible fields | EAV (`field_values` table) | EAV is a documented query/index performance trap (Jira's `customfieldvalue`). |
| **Keyset (cursor) pagination** | `OFFSET` | OFFSET re-scans skipped rows (O(depth)) and skips/duplicates under concurrent writes. |
| **Denormalized read-model columns** maintained at write time | Normalized joins for list screens | "My tasks due this week sorted by date" across two tables has no composite index and no stable cursor. Every hot list must be one index-only scan on one table. |
| **Soft-delete everything** | Hard delete | A hard-delete script caused a multi-week data-loss outage at a major vendor; restore paths are a compliance requirement here. |
| **Codes** (`TSK-…`) as the only public identifiers; tenant = `organization_code` + `school_code` | Numeric ids in APIs / `school_id` | Two sibling services only have codes; ids leak row counts and block cross-service consistency. |
| Notifications via **transactional outbox → Kafka → `communication-service`** | Local notification table + own delivery | The platform already runs reliable delivery; a second path means split-brain notification logic. |
| **No partitioning of occurrence/assignment tables on day one** | Partition from launch | Partition keys must live inside unique constraints — day-one partitioning breaks plain `UNIQUE(code)` lookups. Deferred with an explicit trigger (§26). `audit_log` *is* partitioned from day one (append-only, unbounded, and never looked up by code). |

## 5. How data flows

```
  Admin creates a task (one-off or recurring)
        │  POST /tasks  — assignees as codes; names resolved server-side
        ▼
  ┌─ create transaction ─────────────────────────────────────────────┐
  │ task + assignee roster + initial Window of occurrences/assignments│
  │ + audit_log + outbox(NOTIFY_ASSIGNEES) + idempotency_key         │
  └───────────────┬──────────────────────────────────────────────────┘
                  │                     nightly: window roll + deactivation sweep
                  │                     daily:   activation (roster freeze)
                  ▼
  Staff works their ASSIGNMENT (status/effort/comments/attachments)
        │  PATCH /assignments/{code}
        ▼
  trigger updates the OCCURRENCE rollup (same transaction)
        │
        ▼
  Admin board / calendar / reports read pre-shaped rows
  (index-only keyset scans; projection beyond the Window)

  Notifications: outbox → relay → Kafka `notification-events` → communication-service
  Staff deactivation: staff-service → nightly sweep flags roster INACTIVE → admin notified;
                      untouched future assignments removed (completed history frozen)
```

Writes go through JPA/services (transactions; triggers maintain rollups **and** read-model columns). List reads go through raw SQL/jOOQ against the read-model columns — never ORM graph traversal.

---

# Part II — The data

## 6. Database design

> **Conventions.** Internal PK `BIGINT GENERATED ALWAYS AS IDENTITY` — never exposed; the API speaks public `code`s only. Every table carries the tenant (`organization_code` + `school_code`; `school_code` leads composite indexes), `created_at`/`updated_at` (UTC), `version` (optimistic lock → `409`), `deleted_at`/`deleted_by` (soft delete). Clock times are wall-clock in the **school's IANA time zone**; instants (`*_at`) are UTC `timestamptz`. Tenant/audit columns shown on core tables, elided elsewhere for brevity.

### 6.1 `task` — the series

**Purpose:** the definition and recurrence rule. Owned by its creator/admin. Lives from creation until soft-deleted; `series_status` governs whether it still generates work. Parent of the assignee roster and occurrences. **Carries no execution state** — that lives downstream.

```sql
CREATE TABLE task (
  id                BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code              VARCHAR(40)  NOT NULL UNIQUE,            -- TSK-XXXXXXXX
  organization_code VARCHAR(40)  NOT NULL,
  school_code       VARCHAR(40)  NOT NULL,
  title             VARCHAR(300) NOT NULL,
  description       TEXT         NOT NULL DEFAULT '',

  -- VISIBILITY dimension only (which board/filter shows it). Assignment is the roster (§6.2).
  scope             VARCHAR(16)  NOT NULL DEFAULT 'SCHOOL_WIDE',  -- SCHOOL_WIDE | CLASSROOM
  classroom_code    VARCHAR(40),                             -- required iff scope=CLASSROOM

  -- recurrence RULE (RRULE-lite; single source for generation & projection)
  recurring_flag    BOOLEAN      NOT NULL DEFAULT FALSE,
  rrule_freq        VARCHAR(8),                              -- DAILY | WEEKLY | MONTHLY
  rrule_interval    INT          DEFAULT 1,                  -- every N
  rrule_by_day      VARCHAR(20),                             -- 'MO,WE,FR'
  rrule_by_monthday VARCHAR(20),                             -- '1,15'
  rrule_until       DATE,                                    -- termination (v1: until only; no COUNT)
  series_start_date DATE         NOT NULL,
  series_start_time TIME         NOT NULL DEFAULT '09:00',
  series_end_time   TIME         NOT NULL DEFAULT '17:00',
  holiday_policy    VARCHAR(8)   NOT NULL DEFAULT 'SKIP',    -- SKIP | KEEP (school holidays)

  -- lifecycle (§7.1) + build flag + Window marker
  series_status     VARCHAR(8)   NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE | PAUSED | ENDED
  materialization_status VARCHAR(12) NOT NULL DEFAULT 'READY',  -- READY | BUILDING (large roster only)
  horizon_until     DATE,                                    -- Window materialized up to here

  -- lineage & hierarchy (two DIFFERENT relationships)
  parent_series_id  BIGINT       REFERENCES task(id),        -- THIS_AND_FUTURE split lineage
  parent_task_id    BIGINT       REFERENCES task(id) ON DELETE SET NULL,  -- sub-task, depth 1, v1: one-off only

  -- read model: series-management list reads this, O(1), no LATERAL
  next_occurrence_date   DATE,
  next_occurrence_status VARCHAR(16),

  created_by_code   VARCHAR(40)  NOT NULL,
  created_by_name   VARCHAR(160) NOT NULL,                   -- snapshot
  version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ, deleted_by VARCHAR(40),
  CONSTRAINT chk_task_scope CHECK ((scope='CLASSROOM') = (classroom_code IS NOT NULL))
);
CREATE INDEX idx_task_series ON task (school_code, series_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_task_manage ON task (school_code, next_occurrence_date) WHERE deleted_at IS NULL;
```

| Field | Why it exists |
|---|---|
| `scope`/`classroom_code` | **Visibility only** — where the task surfaces on boards/filters. It may legitimately differ from the roster (a task *about* classroom 1-Blue assigned to the school nurse). This ruling prevents the two concepts silently conflicting. The `CHECK` makes an illegal combination unrepresentable. |
| `rrule_*` | Structured rule → deterministic, testable date math; same vocabulary as the Events schema (shared expansion code). v1 supports `until` termination only — one path to test. |
| `holiday_policy` | A school system must not generate compliance work on holidays. `SKIP` materializes the date as `SKIPPED (HOLIDAY)` (calendar-visible, no assignments); `KEEP` generates normally. Consults the platform holiday calendar at generation. |
| `series_status` | Pause/resume is table stakes in recurring systems; soft delete is *not* pause (§7.1). |
| `materialization_status` | `READY`/`BUILDING` flag only. The Window build is small and usually runs inside the create transaction; `BUILDING` covers a large-roster background build. Deliberately **not** a multi-stage state machine (§4). |
| `horizon_until` | Window marker the nightly job advances. Bounds storage and every fan-out. |
| `parent_series_id` vs `parent_task_id` | Split lineage vs sub-task hierarchy — two relationships, two columns. Hierarchy is v1-restricted to one-off tasks (sub-tasks of a recurring series have unclear semantics — deferred). |
| `next_occurrence_*` | Read model for the series-management list: each series once + next-due summary without a per-row LATERAL. **Refreshed by the nightly/activation jobs only — deliberately NOT trigger-chained from assignment updates**, which would make the series row a write hotspot under concurrent completions. Day-level staleness is accepted and by design. |

**Scaling:** row count ≈ number of distinct tasks ever created (small). Never partitioned.

```
id=900 code=TSK_TEMPCHK title='Daily classroom temperature check' scope=CLASSROOM classroom_code=CLS_71731C8E
recurring_flag=true rrule_freq=WEEKLY rrule_by_day='MO,TU,WE,TH,FR' rrule_until=2026-12-18
series_start_date=2026-06-24 09:00–09:15 holiday_policy=SKIP series_status=ACTIVE
materialization_status=READY horizon_until=2026-07-23 next_occurrence_date=2026-06-24
```

### 6.2 `task_assignee` — the series roster

**Purpose:** the series-level answer to "who does this?" — an explicit, admin-managed staff roster. The generator reads it for every future occurrence; without a series-level "who" record, recurring generation would have no source (the irreducible reason this table exists). Owned by the series (cascade). Staff deactivation flips a row `INACTIVE` and notifies the admin — pending work is **surfaced for reassignment, never silently rewired.**

```sql
CREATE TABLE task_assignee (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,                          -- TAS-XXXXXXXX
  task_id BIGINT NOT NULL REFERENCES task(id) ON DELETE CASCADE,
  organization_code VARCHAR(40) NOT NULL, school_code VARCHAR(40) NOT NULL,
  staff_code VARCHAR(40) NOT NULL,                           -- staff_service is source of truth
  staff_name VARCHAR(160) NOT NULL,                          -- display cache (refreshed while ACTIVE)
  default_priority VARCHAR(8) NOT NULL DEFAULT 'MEDIUM',     -- new assignments inherit this
  status VARCHAR(10) NOT NULL DEFAULT 'ACTIVE',              -- ACTIVE | INACTIVE (deactivated staff; admin must act)
  inactive_since DATE,
  version INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ, deleted_by VARCHAR(40)
);
CREATE INDEX idx_assignee_task ON task_assignee (task_id) WHERE deleted_at IS NULL;
-- one ACTIVE roster row per person per series (soft-deleted rows don't block re-adding)
CREATE UNIQUE INDEX uq_task_assignee ON task_assignee (task_id, staff_code) WHERE deleted_at IS NULL;
CREATE INDEX idx_assignee_staff ON task_assignee (staff_code) WHERE deleted_at IS NULL;  -- deactivation sweep
```

| Field | Why it exists |
|---|---|
| series-level rows | The generator must know who occurrence #47 belongs to, two months from now. This table is that answer — one explicit row per person. |
| `status = INACTIVE` + `inactive_since` | The **human-in-the-loop turnover model**: deactivated staff stop receiving future work, the admin sees "1 assignee inactive" on the series and decides — reassign, remove, or pause. Nothing silent; the summary drops from /10 to /9 while the removed person stays one tap away as history. |
| `uq_task_assignee` partial | One active membership per person per series; re-adding someone previously removed works (their soft-deleted row doesn't collide). |
| `idx_assignee_staff` | The nightly deactivation sweep asks "which rosters carry this staff member?" — one index probe. |
| Upgrade path | If group assignment (classroom/role/department) ever becomes a product requirement, the upgrade is `ADD COLUMN target_type DEFAULT 'USER'` + a resolution job — no schema surgery (§26). |

```
id | code  | task_id | staff_code   | staff_name  | status   | inactive_since
 1 | TAS_1 | 900     | STF_7E922B33 | Brian Lopez | ACTIVE   | NULL
 2 | TAS_2 | 900     | STF_4B721F22 | Diego Patel | INACTIVE | 2026-06-25
 3 | TAS_3 | 900     | STF_2A833D11 | Carla Chen  | ACTIVE   | NULL
```

### 6.3 `task_occurrence` — the dated instance

**Purpose:** the executable unit — "the June-24 temperature check." Owns the per-day rollup, comment thread, and attachments. Created by the generation job; lifecycle in §7.2. Parent of assignments (cascade).

```sql
CREATE TABLE task_occurrence (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,                          -- TOC-XXXXXXXX
  task_id BIGINT NOT NULL REFERENCES task(id) ON DELETE CASCADE,
  organization_code VARCHAR(40) NOT NULL, school_code VARCHAR(40) NOT NULL,
  sequence_number INT NOT NULL,

  original_start_date  DATE NOT NULL,                        -- IDENTITY — never moves
  scheduled_start_date DATE NOT NULL,                        -- where it actually happens (reschedulable)
  scheduled_start_time TIME NOT NULL,
  scheduled_end_time   TIME NOT NULL,

  override_title VARCHAR(300), override_description TEXT,    -- THIS_ONLY edits; NULL → inherit series
  is_modified BOOLEAN NOT NULL DEFAULT FALSE,                -- exception: ALL-edits won't clobber it

  status VARCHAR(12) NOT NULL DEFAULT 'SCHEDULED',           -- SCHEDULED|ACTIVE|CANCELLED|SKIPPED (§7.2)
  status_reason VARCHAR(24),                                 -- ADMIN|HOLIDAY|SERIES_PAUSED|SERIES_SPLIT
  activated_at TIMESTAMPTZ,                                  -- set by the activation job = roster freeze

  -- rollup (trigger-kept, in-txn) — completion is DERIVED, not a status
  assignment_total INT NOT NULL DEFAULT 0,
  assignment_in_progress INT NOT NULL DEFAULT 0,
  assignment_completed INT NOT NULL DEFAULT 0,
  aggregate_status VARCHAR(16) GENERATED ALWAYS AS (
    CASE WHEN assignment_total = 0                                    THEN 'EMPTY'
         WHEN assignment_completed = assignment_total                 THEN 'COMPLETED'
         WHEN assignment_completed = 0 AND assignment_in_progress = 0 THEN 'NOT_STARTED'
         ELSE 'IN_PROGRESS' END) STORED,

  version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ, deleted_by VARCHAR(40),
  UNIQUE (task_id, original_start_date)                      -- duplicates structurally impossible
);  -- NOT partitioned on day one (§26): global UNIQUE(code) = one-probe lookups
CREATE INDEX idx_occ_calendar ON task_occurrence (school_code, scheduled_start_date, aggregate_status)
  WHERE deleted_at IS NULL;
```

| Field | Why it exists |
|---|---|
| `original_start_date` vs `scheduled_start_date` | Reschedule-safe identity (Events v4 pattern): "move Monday's check to Tuesday" keeps identity, and re-running the generator can't duplicate it. |
| `UNIQUE (task_id, original_start_date)` | With `ON CONFLICT DO NOTHING`, generation is **idempotent** — crash recovery, self-heal, and restore all come free. The design's keystone. |
| `activated_at` + `status=ACTIVE` | The **freeze boundary** (§7.2/§9). Roster cascades touch only `SCHEDULED`; an activated roster can never be altered by a roster change or deactivation. |
| `aggregate_status` GENERATED STORED | Indexable, sortable, and **cannot drift** — Postgres computes it from the counters; no second trigger. Completion is derived, never a manually-set status. |
| `EMPTY` | An occurrence with no assignees is visible, not silent — surfaced to admin (an unstartable occurrence is a staffing signal). |
| not partitioned yet | Partition keys must live inside unique constraints; day-one partitioning would break `UNIQUE(code)` lookups. Deferred with an explicit trigger (§26). |

**Scaling:** the first of two unbounded-growth tables (≈ active series × window days, plus history). Partition by month when a tenant crosses ~a few million rows; archive by detaching partitions.

```
id   | code     | original_start | scheduled_start | status    | status_reason | aggregate_status
5001 | TOC_0624 | 2026-06-24     | 2026-06-24      | ACTIVE    | NULL          | IN_PROGRESS
5002 | TOC_0625 | 2026-06-25     | 2026-06-25      | SCHEDULED | NULL          | NOT_STARTED
50xx | TOC_0704 | 2026-07-04     | 2026-07-04      | SKIPPED   | HOLIDAY       | EMPTY
```

### 6.4 `task_assignment` — per-person execution

**Purpose:** the atom of work and reporting — "Brian's June-24 check." Created by resolution (or manual add). Carries the **read-model columns** that make every staff-facing list a single-table scan. Frozen into history at terminal status.

```sql
CREATE TABLE task_assignment (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,                          -- TSA-XXXXXXXX
  occurrence_id BIGINT NOT NULL REFERENCES task_occurrence(id) ON DELETE CASCADE,
  organization_code VARCHAR(40) NOT NULL, school_code VARCHAR(40) NOT NULL,

  assignee_code VARCHAR(40) NOT NULL,                        -- staff_service is source of truth
  assignee_name VARCHAR(160) NOT NULL,                       -- CACHE while open; FREEZES at terminal status
  is_manual_override BOOLEAN NOT NULL DEFAULT FALSE,         -- added to THIS occurrence only (not on the series roster)

  -- READ MODEL: copied so "My Tasks" is one index-only keyset scan (maintained at write time)
  occurrence_date DATE NOT NULL,                             -- = occurrence.scheduled_start_date
  due_at TIMESTAMPTZ NOT NULL,                               -- = scheduled_start_date + scheduled_end_time, school tz
  title VARCHAR(300) NOT NULL,                               -- effective (override ?? series)
  task_code VARCHAR(40) NOT NULL,                            -- deep-link without a join

  status VARCHAR(16) NOT NULL DEFAULT 'TO_DO',               -- TO_DO|IN_PROGRESS|COMPLETED
  status_rank SMALLINT NOT NULL DEFAULT 0,
  priority VARCHAR(16) NOT NULL DEFAULT 'MEDIUM',
  priority_rank SMALLINT NOT NULL DEFAULT 1,                 -- LOW=0 MED=1 HIGH=2 (text sorts wrong; CASE can't use an index)
  effort NUMERIC(6,2) NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,

  version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ, deleted_by VARCHAR(40)
);  -- NOT partitioned on day one (§26)
CREATE UNIQUE INDEX uq_assign_active ON task_assignment (occurrence_id, assignee_code)
  WHERE deleted_at IS NULL;    -- one ACTIVE row per person/occurrence; re-adding a removed person works
-- the My-Tasks workhorse: filter + window + sort + display columns in ONE index → index-only scan
CREATE INDEX idx_my_tasks ON task_assignment (assignee_code, school_code, occurrence_date, id)
  INCLUDE (title, status, priority, due_at, task_code) WHERE deleted_at IS NULL;
-- overdue: an index predicate CANNOT contain now() (not immutable); the query supplies due_at < now()
CREATE INDEX idx_assign_open_due ON task_assignment (school_code, due_at)
  WHERE status <> 'COMPLETED' AND deleted_at IS NULL;
-- reporting: month-bounded aggregations per school (§17)
CREATE INDEX idx_assign_report ON task_assignment (school_code, occurrence_date) WHERE deleted_at IS NULL;
```

| Field | Why it exists |
|---|---|
| `occurrence_id` (not `task_id`) | Execution hangs off the occurrence → Monday's status/thread genuinely separate from Tuesday's. |
| read-model columns | Without them, "my tasks due this week sorted by date" is a cross-table join+sort with **no stable keyset cursor** — the app's most-used screen becomes its slowest. Copied at resolve/reschedule/retitle; every fan-out is bounded by the Window. `INCLUDE(title)` costs index size — accepted consciously for heap-free scans. |
| `assignee_name` cache→freeze | Refreshable display cache while open (offline rendering without a service call); freezes at terminal status so "Completed by Alice" survives Alice's resignation. |
| `is_manual_override` | Marks a person added to a **single occurrence** without joining the series roster ("cover just this day") — roster cascades never touch these rows, and the UI can label them distinctly. |
| `uq_assign_active` partial | Plain UNIQUE would block re-adding a previously removed person (their soft-deleted row would collide). A classic missed bug. |

**Concurrency:** the counter trigger fires on `INSERT` and `UPDATE OF status, deleted_at` (a soft delete must decrement). Lock order is always **assignment → occurrence** to prevent deadlocks.

**Scaling:** the second unbounded table (occurrences × roster). Same partitioning trigger as §6.3.

```
id   | code     | occ  | assignee     | assignee_name | manual | status      | completed_at
8001 | TSA_9001 | 5001 | STF_7E922B33 | Brian Lopez   | false  | COMPLETED   | 06-24 09:07
8002 | TSA_9002 | 5001 | STF_4B721F22 | Diego Patel   | false  | IN_PROGRESS | NULL
8003 | TSA_9003 | 5001 | STF_2A833D11 | Carla Chen    | false  | TO_DO       | NULL
→ occurrence 5001: total=3, completed=1, in_progress=1 → aggregate_status=IN_PROGRESS
```

### 6.5 `task_comment` — discussion, three scopes

**Purpose:** conversation at the right granularity — a **series** note ("always use the wall thermometer"), a **day** thread ("today's reading was high, escalated"), a **private** assignee↔admin thread ("out sick, Carla covers"). The `CHECK` guarantees exactly one target — a comment can never be orphaned or double-scoped.

```sql
CREATE TABLE task_comment (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE, school_code VARCHAR(40) NOT NULL,
  task_id            BIGINT REFERENCES task(id)            ON DELETE CASCADE,
  task_occurrence_id BIGINT REFERENCES task_occurrence(id) ON DELETE CASCADE,
  task_assignment_id BIGINT REFERENCES task_assignment(id) ON DELETE CASCADE,
  author_code VARCHAR(40) NOT NULL, author_name VARCHAR(160) NOT NULL,   -- snapshot, never refreshed
  body TEXT NOT NULL,                                        -- 1..4000 chars, sanitized
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,                  -- UI flag; before/after lives in audit_log
  version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ, deleted_by VARCHAR(40),
  CONSTRAINT chk_comment_target CHECK (
    (task_id IS NOT NULL)::int + (task_occurrence_id IS NOT NULL)::int + (task_assignment_id IS NOT NULL)::int = 1)
);
CREATE INDEX idx_comment_occ    ON task_comment (task_occurrence_id, created_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_comment_assign ON task_comment (task_assignment_id, created_at) WHERE deleted_at IS NULL;
```

Deletes are soft (thread renders "deleted"); comments on occurrences later cancelled by a split remain attached as history. *Editable vs immutable: open decision §27.*

### 6.6 `attachment` — versioned files with full history

**Purpose:** files with a provable add/replace/delete chain. The DB stores only the object-store `storage_key` — never bytes. Polymorphic owner (series / occurrence / assignment / comment) with a `CHECK` for exactly one.

```sql
CREATE TABLE attachment (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,                          -- ATT-… stable across versions
  school_code VARCHAR(40) NOT NULL,
  task_id BIGINT REFERENCES task(id) ON DELETE CASCADE,
  task_occurrence_id BIGINT REFERENCES task_occurrence(id) ON DELETE CASCADE,
  task_assignment_id BIGINT REFERENCES task_assignment(id) ON DELETE CASCADE,
  comment_id BIGINT REFERENCES task_comment(id) ON DELETE CASCADE,
  version INT NOT NULL DEFAULT 1, is_current BOOLEAN NOT NULL DEFAULT TRUE,
  status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',              -- ACTIVE | DELETED
  file_name VARCHAR(300) NOT NULL, storage_key TEXT NOT NULL,
  mime_type VARCHAR(80) NOT NULL, size_bytes BIGINT NOT NULL, checksum VARCHAR(64),
  uploaded_by VARCHAR(40) NOT NULL, uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_by VARCHAR(40), deleted_at TIMESTAMPTZ,
  CONSTRAINT chk_attach_owner CHECK (
    (task_id IS NOT NULL)::int + (task_occurrence_id IS NOT NULL)::int
    + (task_assignment_id IS NOT NULL)::int + (comment_id IS NOT NULL)::int = 1)
);
```

**Lifecycle:** Add → v1. Replace → new row, same `code`, `version+1`, prior row `is_current=false` (blob retained → revision chain). Delete → soft; blob kept for restore, expired by storage lifecycle policy. Uploads are validated server-side (JPEG/PNG/WebP/PDF, ≤10 MB), malware-scanned before `ACTIVE`; reads use short-lived pre-signed URLs. Every action audited.

### 6.7 `audit_log` — compliance history (month-partitioned from day one)

**Purpose:** the immutable answer to "who changed what, when, from→to" for every entity. Written **in the same transaction** as the mutation — history can never disagree with state.

```sql
CREATE TABLE audit_log (
  id BIGINT GENERATED ALWAYS AS IDENTITY,
  school_code VARCHAR(40) NOT NULL,
  entity_type VARCHAR(24) NOT NULL,          -- TASK|TARGET|OCCURRENCE|ASSIGNMENT|COMMENT|ATTACHMENT
  entity_code VARCHAR(40) NOT NULL,
  action VARCHAR(32) NOT NULL,               -- CREATED|UPDATED|STATUS_CHANGED|SERIES_SPLIT|PAUSED|RESOLVED|…
  actor_code VARCHAR(40) NOT NULL, actor_name VARCHAR(160) NOT NULL,   -- snapshot; 'SYSTEM' for jobs
  correlation_id UUID,                       -- stitches one user action across job/outbox side-effects
  changes JSONB,                             -- {"status":{"from":"TO_DO","to":"COMPLETED"}}
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);
CREATE INDEX idx_audit_entity ON audit_log (school_code, entity_type, entity_code, created_at DESC);
```

Append-only and unbounded → partitioned monthly from the start; old months **detach & archive** (a metadata operation, not a giant DELETE). It is never looked up by a unique code, so partitioning costs nothing here.

### 6.8 Reliability spine: `outbox` + `idempotency_key`

```sql
CREATE TABLE outbox (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  aggregate_type VARCHAR(24) NOT NULL, aggregate_code VARCHAR(40) NOT NULL,
  event_type VARCHAR(40) NOT NULL,           -- NOTIFY_ASSIGNEES|DUE_TODAY|OVERDUE|SERIES_ENDING|…
  school_code VARCHAR(40) NOT NULL, payload JSONB NOT NULL,
  status VARCHAR(12) NOT NULL DEFAULT 'PENDING', attempts INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), processed_at TIMESTAMPTZ
);
CREATE TABLE idempotency_key (
  key UUID PRIMARY KEY, school_code VARCHAR(40) NOT NULL,
  response_code INT, response_body JSONB, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

- **`outbox` is for notifications only.** An event row commits atomically with the business change; a relay publishes to Kafka `notification-events`; `communication-service` delivers. A crash never loses a notification; a rollback never sends one. `attempts` drives bounded retry. Generation does **not** use the outbox (it's an idempotent job — §8).
- **`idempotency_key`:** a client that retries a `POST` on a flaky network gets the *original* response back, never a duplicate task.
- `sync_inbox` (Kafka consumer dedup) ships only with the deferred event-driven staff-status sync (§26); v1's nightly sweep needs neither.

## 7. Lifecycles and invariants

*The part diagrams hide and production exposes. Every transition has exactly one owner, and two protection rules govern all of them.*

### 7.0 The two protection rules

> **Cascade invariant.** Any series/occurrence lifecycle change (delete, pause, cancel, split, reschedule, retitle-ALL) **must cascade to its assignment rows in the same transaction.** The read model reads *only* `task_assignment` — an un-cascaded change leaves ghost work in "My Tasks." Bounded by the Window, so always cheap.

> **Touched-work protection.** Only rows with `status = TO_DO` and `is_manual_override = false` may ever be soft-deleted by a roster cascade (assignee removal, staff deactivation) or a lifecycle cascade. A row with `status ≠ TO_DO` is a **fact** — staff may legitimately start or complete a future occurrence early, and no roster change or series edit may destroy recorded work. (Without this rule, a teacher who finishes Friday's task on Wednesday and is deactivated on Thursday would have her completed work deleted by the nightly sweep.)

### 7.1 Series: `series_status = ACTIVE | PAUSED | ENDED` (+ soft delete)

| Transition | Owner | What happens (one transaction) |
|---|---|---|
| **Pause** | admin/creator | Stop generation. Future `SCHEDULED` occurrences → `CANCELLED (SERIES_PAUSED)`; their **`TO_DO`** assignments soft-deleted (touched rows preserved). Past/ACTIVE untouched. |
| **Resume** | admin/creator | Future `SERIES_PAUSED` occurrences flip back to `SCHEDULED`; assignments **regenerated from the current ACTIVE roster** (it may have changed while paused); generation resumes. |
| **End** | nightly job / admin | `rrule_until` passed or manual. No further generation; history remains. |
| **Delete** | admin/creator | Soft-delete series + future `SCHEDULED` occurrences + their `TO_DO` assignments. **Past history is never deleted.** Today's `ACTIVE` occurrences remain finishable (default; decision §27). |
| **Restore** | admin | Clear `deleted_at`; re-run `materializeWindow` — idempotent generation rebuilds the Window. |

### 7.2 Occurrence: `status = SCHEDULED | ACTIVE | CANCELLED | SKIPPED`

```
 (generated) ──▶ SCHEDULED ──daily activation job──▶ ACTIVE
                     │
                     ├─ cancel/skip (admin, holiday, pause, split) ──▶ CANCELLED | SKIPPED (status_reason)
 "completed" is NOT a status — it is DERIVED (aggregate_status) from assignment counts.
```

- **Activation = the freeze boundary** (§9): a daily job flips today's `SCHEDULED → ACTIVE`, stamps `activated_at`, notifies. Roster cascades only ever touch `SCHEDULED`.
- `CANCELLED/SKIPPED` = calendar EXDATE: drop one date without harming the series. Cancelling soft-deletes the occurrence's **`TO_DO`** assignments (both protection rules apply).
- Reschedule: `scheduled_start_date` moves, identity doesn't; child assignments' `occurrence_date/due_at` update in the same txn. **Rescheduling into today activates immediately** (it would otherwise miss the day's activation run).

### 7.3 Assignment: `status = TO_DO | IN_PROGRESS | COMPLETED`

Created by resolution or manual add. `COMPLETED` stamps `completed_at`; the counter trigger updates the occurrence rollup in-transaction; `assignee_name` freezes at terminal status.

### 7.4 Roster-change timing

The roster is explicit, so there is nothing to "resolve" — only to propagate: **adding** an assignee backfills assignments into already-materialized future `SCHEDULED` occurrences (same transaction); **removing** one (or a staff deactivation) soft-deletes their untouched future rows per §7.0. Activation freezes each day's roster. Past is immutable.

---

# Part III — The recurrence engine

## 8. Generation — `materializeWindow`

One idempotent routine, called at create (initial Window) and nightly (roll forward + self-heal). The only remote call in the create path is resolving staff **names** when the roster is first built — done via gRPC *before* the transaction opens (remote calls inside an open transaction hold locks hostage to network latency). Generation itself reads the local roster.

```
routine materializeWindow(task, fromDate, toDate):
  roster   := ACTIVE task_assignee rows of task             -- local read; names already cached, no remote call
  holidays := holidayCalendar(school, fromDate..toDate)     -- platform service, read BEFORE the txn

  BEGIN TX (advisory lock on task.id)                       -- serializes vs splits & roster cascades
    for each rule-date D in expandRRULE(task, fromDate, toDate):
      if D in holidays and task.holiday_policy = 'SKIP':
        INSERT task_occurrence (…, D, status='SKIPPED', status_reason='HOLIDAY')
          ON CONFLICT (task_id, original_start_date) DO NOTHING       -- no assignments
      else:
        occ := INSERT task_occurrence (…, D, status='SCHEDULED')
                 ON CONFLICT (task_id, original_start_date) DO NOTHING
        if newly inserted:
          INSERT task_assignment (occ, m, occurrence_date=D, due_at, title, task_code)  for m in roster
          if roster is empty → audit(OCCURRENCE_EMPTY) + admin notification via outbox
    task.horizon_until := toDate;  refresh task.next_occurrence_*
  COMMIT
```

- **Recovery = idempotency, not a state machine.** A crashed or double-run job fills gaps and duplicates nothing. Restore-after-delete reuses the same property.
- **WINDOW = 60–90 days** (configurable). It bounds storage and the blast radius of *every* change.
- Create: small roster → runs inside the create transaction (task `READY` immediately; `201` returns `occurrenceCount`). Large roster → quick background build, `BUILDING → READY`.
- Back-dated `series_start_date` is **rejected** (`422 BACKDATED_SERIES`); historical import is a separate admin feature if ever needed (§27).

## 9. Activation — the freeze boundary

Per school, at start of school day (school tz): flip today's `SCHEDULED → ACTIVE`, stamp `activated_at`, enqueue due-today notifications. From this moment the day's roster is frozen — no roster change can alter who owns today's work.

## 10. Roster changes and staff deactivation

Three events change who owns future work — all bounded by the Window, all obeying §7.0:

1. **Admin adds an assignee** (`POST /tasks/{code}/assignees`): insert the `task_assignee` row **and backfill** assignments into already-materialized future `SCHEDULED` occurrences, in the same transaction. Newly generated occurrences include them automatically.
2. **Admin removes an assignee** (`DELETE /tasks/{code}/assignees/{staffCode}`): soft-delete the roster row and the person's untouched (`TO_DO`, non-manual) assignments on future `SCHEDULED` occurrences. Started/completed rows stay.
3. **Staff deactivated in staff-service** (nightly sweep via `idx_assignee_staff`; event-driven is the deferred upgrade — §26): flip their roster rows to `INACTIVE` + `inactive_since`, cascade untouched future rows as in (2), recompute counters, and **notify the admin** (`ASSIGNEE_INACTIVE`). The series then visibly shows "1 assignee inactive" until the admin reassigns, removes, or pauses. Nothing is silently rewired: the summary drops from /10 to /9, and the removed person remains one tap away as history (soft-deleted rows + audit).

Past and `ACTIVE` occurrences are never modified — history is what actually happened.

## 11. Projection — the calendar beyond the Window

Materialized rows exist only inside the Window, but users page calendars further ahead. Reads past `horizon_until` **merge materialized rows with projected ones**, computed from the RRULE (+ holiday calendar) at read time:

```jsonc
{ "date": "2026-11-16", "title": "Daily classroom temperature check", "projected": true }
// no code, no assignments — display-only; UI renders dimmed/uninteractive
```

Pure function of the rule → no writes from reads, infinite forward navigation, and the Window still bounds all real rows. (This is precisely how calendar products render "forever" without storing it.)

## 12. Editing a series

| Scope | Mechanics (all obey both protection rules) |
|---|---|
| **THIS_ONLY** | Update the one occurrence (`override_*`/reschedule, `is_modified=true`); cascade `occurrence_date/due_at/title` to its assignments. ALL-edits never clobber `is_modified` rows. |
| **THIS_AND_FUTURE** | **Series split**, one txn: cap old series (`rrule_until = day-1`); `CANCEL (SERIES_SPLIT)` its future `SCHEDULED` occurrences + soft-delete their `TO_DO` assignments; insert new series (`parent_series_id` = old, **ACTIVE roster copied**); materialize it. |
| **ALL** | Update the series; batch-update future non-exception occurrences + their assignments' read-model copies (bounded by the Window); exceptions keep overrides. |
| **CANCEL/SKIP one** | Occurrence status change + `TO_DO`-assignment cascade. Never a hard delete. |

## 13. Pause, delete, restore

Semantics in §7.1. Implementation notes: pause's `CANCELLED (SERIES_PAUSED)` rows deliberately **block** `ON CONFLICT` regeneration; resume flips exactly those rows back to `SCHEDULED` and regenerates assignments from the current ACTIVE roster — reusing existing machinery, no special cases. Restore = clear `deleted_at` + `materializeWindow`.

## 14. Background jobs

All jobs are **per-school sharded, per-series transactions, advisory-locked** — never one global transaction.

| Job | When | Does | On failure |
|---|---|---|---|
| Window roll | nightly | `materializeWindow(horizon_until+1 … today+WINDOW)` per active series; mark `ENDED` when rule exhausted; refresh `next_occurrence_*` | idempotent — next run fills gaps; alert on repeated failure |
| Staff-deactivation sweep | nightly (same pass) | §10.3: flag INACTIVE roster rows, cascade untouched future rows, notify admin | same |
| Activation | daily, school-day start (school tz) | §9 | rerunnable (flips only remaining `SCHEDULED` of today) |
| Outbox relay | continuous | publish `PENDING` outbox rows to Kafka; bump `attempts` | bounded retry; dead-letter + alert past threshold |
| Reconciliation | nightly | recompute counters from source; alert on drift | report-only |
| Retention | monthly | detach/archive old `audit_log` partitions; purge soft-deleted rows + orphaned blobs past grace period | resumable |

---

# Part IV — Serving the product

## 15. Backend response design, screen by screen

**Global conventions.** Envelope `{ success, message, data }`; errors `400/401/403/404/409/422/429` with machine codes (`VERSION_CONFLICT`, `DUE_BEFORE_START`, `BACKDATED_SERIES`, …). Mutations send `version`/`If-Match` → `409` on staleness. Creates send `Idempotency-Key`. Identity and tenant come from the JWT — never the body; clients send **codes**, the server resolves names. **Pagination is keyset everywhere:** order by `(sortKey, id)`, cursor = last row's tuple (base64, opaque), `nextCursor` in every list response, no `OFFSET`, no totals. Sorting is a **curated allow-list per endpoint**, each option backed by an index; enum sorts use `*_rank` columns (text would sort `HIGH < LOW < MEDIUM`; a `CASE` in `ORDER BY` can't use an index). Date-range filters are **mandatory server-side** (defaulted when omitted) — no unbounded scans. The invariant behind every list: **one index-only, keyset-paginated scan on one table.**

### 15.1 Staff "My Tasks"

- **API:** `GET /api/v1/me/assignments?from&to&status&priority&overdue&sort=dueDate&cursor&limit`
- **Filters:** date window (mandatory/defaulted), status, priority, overdue, text search (title). Assignee is implicit (`= me` from JWT).
- **Query:** driving table `task_assignment` **alone** — no joins; index `idx_my_tasks` (filter + window + sort + display columns in one covering index → index-only scan).

```sql
SELECT code, task_code, title, occurrence_date, due_at, status, priority
  FROM task_assignment
 WHERE assignee_code = :me AND school_code = :school AND deleted_at IS NULL
   AND occurrence_date BETWEEN :from AND :to
   AND (:status IS NULL OR status = :status)
   AND (:curDate IS NULL OR (occurrence_date, id) > (:curDate, :curId))
 ORDER BY occurrence_date, id LIMIT :limit;
```

```jsonc
{ "success": true, "message": "My tasks",
  "data": { "items": [
      { "code":"TSA_9002","taskCode":"TSK_TEMPCHK","title":"Daily classroom temperature check",
        "occurrenceDate":"2026-06-24","dueAt":"2026-06-24T09:15:00-05:00","status":"TO_DO","priority":"MEDIUM" },
      { "code":"TSA_9018","taskCode":"TSK_TEMPCHK","title":"Daily classroom temperature check",
        "occurrenceDate":"2026-06-25","dueAt":"2026-06-25T09:15:00-05:00","status":"TO_DO","priority":"MEDIUM" } ],
    "nextCursor":"eyJkIjoiMjAyNi0wNi0yNSIsImlkIjo5MDE4fQ==", "timeZone":"America/Chicago" } }
```

- **Why this shape:** flat, self-sufficient rows — the mobile card renders with zero extra calls and caches directly into Isar for offline; a recurring task correctly appears once per due date; latency is flat at any history size or page depth. *Only possible because of the read-model columns — and only trustworthy because of the cascade invariant* (a deleted/paused series vanishes from this index in the same transaction that changes it).

### 15.2 Admin ops board / calendar feed

- **API:** `GET /api/v1/tasks?view=OCCURRENCES&from&to&status&classroomCode&scope&overdue&q&sort=date&cursor&limit` *(default view)*
- **Filters:** date window (mandatory/defaulted), aggregate status, classroom/scope, overdue, search.
- **Query:** driving table `task_occurrence` on `idx_occ_calendar`; ≤ `limit` primary-key joins to `task` for the title only.

```sql
SELECT o.code, COALESCE(o.override_title, t.title) AS title, o.scheduled_start_date,
       o.status, o.status_reason, o.aggregate_status, o.assignment_total, o.assignment_completed
  FROM task_occurrence o
  JOIN task t ON t.id = o.task_id
 WHERE o.school_code = :school AND o.deleted_at IS NULL
   AND o.scheduled_start_date BETWEEN :from AND :to
   AND (:status IS NULL OR o.aggregate_status = :status)
   AND (:cur IS NULL OR (o.scheduled_start_date, o.id) > (:curDate, :curId))
 ORDER BY o.scheduled_start_date, o.id LIMIT :limit;
```

```jsonc
{ "data": { "items": [
    { "code":"TOC_0624", "title":"Daily classroom temperature check", "date":"2026-06-24",
      "status":"ACTIVE", "aggregateStatus":"IN_PROGRESS",
      "rollup": { "total":3, "completed":1, "progressPercent":33 } },
    { "code":"TOC_0704", "title":"Daily classroom temperature check", "date":"2026-07-04",
      "status":"SKIPPED", "statusReason":"HOLIDAY", "aggregateStatus":"EMPTY" } ],
  "nextCursor": null, "timeZone":"America/Chicago" } }
```

- **Why this shape:** the board *is* the calendar feed — one endpoint serves both. Rollups are pre-computed columns (no live COUNT over assignments); SKIPPED/HOLIDAY rows render as calendar context. Requests past `horizon_until` merge **projected** items (§11).

### 15.3 Series management list

- **API:** `GET /api/v1/tasks?view=SERIES&seriesStatus&recurring&q&sort=nextDue&cursor&limit`
- **Query:** `task` table alone on `idx_task_manage` — each series **once** with its `next_occurrence_*` read-model summary. O(1) per row, no joins, no LATERAL.

```jsonc
{ "data": { "items": [
    { "code":"TSK_TEMPCHK", "title":"Daily classroom temperature check", "recurring":true,
      "seriesStatus":"ACTIVE", "rrule":{"freq":"WEEKLY","byDay":["MO","TU","WE","TH","FR"],"until":"2026-12-18"},
      "nextOccurrenceDate":"2026-06-25", "nextOccurrenceStatus":"NOT_STARTED" } ],
  "nextCursor": null } }
```

- **Why:** admins managing rules need one row per rule (pause/edit/delete affordances) — a different question from the ops board, so a different view, not a conflated one. Day-level staleness of the summary is by design (§6.1).

### 15.4 Occurrence detail (past or future — same query)

- **API:** `GET /api/v1/occurrences/{occurrenceCode}`
- **Query:** four bounded index lookups, assembled server-side: occurrence by global `UNIQUE(code)`; its assignments (FK index); first comment page (`idx_comment_occ`, keyset for more); current attachments (partial index).

```jsonc
{ "data": {
    "occurrence": { "code":"TOC_0624","title":"Daily classroom temperature check","date":"2026-06-24",
                    "status":"ACTIVE","aggregateStatus":"IN_PROGRESS",
                    "rollup":{"total":3,"completed":1,"inProgress":1} },
    "assignments": [
      { "code":"TSA_9001","assigneeName":"Brian Lopez","status":"COMPLETED","completedAt":"2026-06-24T09:07:00-05:00" },
      { "code":"TSA_9002","assigneeName":"Diego Patel","status":"IN_PROGRESS" },
      { "code":"TSA_9003","assigneeName":"Carla Chen","status":"TO_DO" } ],
    "removedAssignees": [],   // soft-deleted rows (e.g. deactivated staff) — the "was 10, now 9" story stays visible
    "comments": { "items":[ { "code":"CMT_1","authorName":"Diego Patel","body":"Thermometer battery low",
                              "createdAt":"2026-06-24T09:10:00-05:00" } ], "nextCursor": null },
    "attachments": [], "timeZone":"America/Chicago" } }
```

- **Why:** one call paints the whole screen (no client-side assembly, no N+1). **Past and future use the identical query** — a past occurrence's assignments are simply frozen history with names locked at completion.

### 15.5 Person view (admin)

- **API:** `GET /api/v1/assignments?assigneeCode=STF_…&from&to&status&…` — same query/index/response shape as My Tasks (15.1) with an explicit assignee. One implementation serves both.

### 15.6 Comment threads

- **API:** `GET|POST /api/v1/{owner}/{code}/comments` (owner ∈ `tasks|occurrences|assignments`), `PATCH|DELETE /api/v1/comments/{commentCode}`.
- Oldest→newest, keyset on `(created_at, id)`. POST body `{ "body": "…" }`; author resolved from the JWT. Optimistic UI: clients render immediately with a local id, reconcile on the `201`.

### 15.7 Reports — see §17.

## 16. Calendar behavior

- **Why occurrences exist:** each calendar cell is a real row that can hold status, comments, and attachments — a purely computed calendar cannot (§4).
- **Within the Window:** cells come from `task_occurrence` via 15.2. Recurring tasks appear once per date. `SKIPPED (HOLIDAY)` and `CANCELLED` render with their reason; rescheduled occurrences appear on their new date (identity preserved); `is_modified` exceptions show their overridden title.
- **Beyond the Window (infinite forward scrolling):** projected items (§11) — computed, dimmed, uninteractive. Interacting with real work requires a materialized row, which the Window guarantees for the next 60–90 days.
- **The past (history):** rows persist forever (later: archived partitions serve cold reads with higher latency — acceptable, stated). A deleted series' **past** occurrences remain calendar-visible as history.
- **Example:** paging to November 2026 (past the July horizon) shows "temperature check" on every weekday as `projected:true`; paging to last month shows real rows with completion states — including June-24's `1/3 → 3/3` progression exactly as it happened.

## 17. Reporting

Reports are **month/period-bounded aggregations** run against live tables (pre-aggregates are a deferred upgrade with an explicit trigger — §26). All report queries filter `school_code + occurrence_date` range → driven by `idx_assign_report`. Responses are `{ summary, rows[] }` — bounded by the period, no cursor needed.

**Staff performance (monthly/yearly)** — `GET /api/v1/reports/staff-performance?from&to`

```sql
SELECT assignee_code, MIN(assignee_name) AS name,
       COUNT(*)                                                            AS total,
       COUNT(*) FILTER (WHERE status='COMPLETED')                          AS completed,
       COUNT(*) FILTER (WHERE status='COMPLETED' AND completed_at <= due_at) AS on_time,
       COUNT(*) FILTER (WHERE status<>'COMPLETED' AND occurrence_date < CURRENT_DATE) AS missed
  FROM task_assignment
 WHERE school_code=:school AND occurrence_date BETWEEN :from AND :to AND deleted_at IS NULL
 GROUP BY assignee_code ORDER BY name;
```

```jsonc
{ "data": { "period":{"from":"2026-06-01","to":"2026-06-30"},
    "summary":{"total":412,"completed":371,"onTime":344,"missed":28,"completionRate":90},
    "rows":[ {"assigneeCode":"STF_7E922B33","name":"Brian Lopez","total":22,"completed":22,"onTime":21,"missed":0} ] } }
```

**Definitions (fixed, so every report agrees):** *completed* = `status=COMPLETED`; *on-time* = `completed_at <= due_at`; **missed** = `status <> COMPLETED AND occurrence_date < today` (terminal, reportable); **overdue** = same predicate but *live and still actionable* — a UI state, not a report row.

**Classroom performance** — same aggregation grouped by `t.classroom_code` via `assignment → occurrence → task` joins (`scope='CLASSROOM'`). A 3-table join bounded by one month is acceptable at launch; if it slows, the escape hatches are denormalizing `classroom_code` onto assignments or monthly pre-aggregate tables (§26).

**Recurring compliance (one series)** — `GET /api/v1/reports/series-compliance?taskCode&from&to`: `task_occurrence` rows of the series in the period (`original_start_date, status, status_reason, aggregate_status, completed/total`) — shows every scheduled date including SKIPPED/HOLIDAY, which is precisely what an auditor asks for.

**Overdue right now** — `idx_assign_open_due` with `due_at < now()` supplied by the query, grouped by assignee or task.

## 18. Notifications

| Event | Trigger point | Recipients |
|---|---|---|
| `TASK_ASSIGNED` | create / roster add / occurrence-level manual add / resume | new assignees |
| `DUE_TODAY` | activation job (§9) | today's roster |
| `OVERDUE` | daily scan (open + `due_at < now()`) | assignee (+ escalation later, §26) |
| `COMMENT_ADDED` | comment POST | thread participants minus author |
| `OCCURRENCE_EMPTY` | generation found an empty roster | admin |
| `ASSIGNEE_INACTIVE` | deactivated staff found on active rosters (nightly sweep) | admin — reassign / remove / pause |
| `SERIES_ENDING` | nightly (rule ends within N days) | creator/admin |

**Flow (exactly one path):** business transaction writes the `outbox` row → relay publishes to Kafka `notification-events` (payload: `notification_type`, `recipient_code`, `template_key`, deep-link, `correlation_id`) → `communication-service` delivers push/in-app/email. Crash-safe (outbox), retried (`attempts`), rollback-safe (row never commits), deduplicated downstream by outbox id. **No local notification table.**

---

# Part V — Workflows end-to-end

## 19. Workflows

Each: trigger → processing → DB effects → result. All obey §7.0's two protection rules.

**W1 — Create one-off task.** `POST /tasks` (assignees = staff codes). Names resolved via gRPC before the txn. One txn: `task (recurring_flag=false)` + `task_assignee` roster + **one** occurrence + assignments + `audit(CREATED)` + `outbox(TASK_ASSIGNED)` + idempotency row. → `201 READY`; assignees notified; task appears in their My Tasks.

**W2 — Create recurring task.** Same as W1, but `expandRRULE` fills the initial Window (holiday-aware). Small roster → in-txn, `READY` immediately with `occurrenceCount`; large roster → `BUILDING`, quick background build, then `READY`.

**W3 — Nightly scheduler.** Per school, per series (advisory-locked txn): roll the Window (§8), run the staff-deactivation sweep (§10.3), mark exhausted rules `ENDED`, refresh `next_occurrence_*`. Idempotent → a re-run or crash costs nothing.

**W4 — Daily activation.** Flip today's `SCHEDULED → ACTIVE` per school tz; stamp `activated_at`; `outbox(DUE_TODAY)`. Rosters for today are now frozen.

**W5 — Staff completes a task.** `PATCH /assignments/TSA_9001 {status:COMPLETED}` with `If-Match`. One txn: status + `completed_at` + version bump; name freezes; counter trigger updates occurrence rollup → `aggregate_status` recomputes (generated column); `audit(STATUS_CHANGED {from,to})`. → `200`; admin board reflects `2/3` on next read.

**W6 — Staff comments.** `POST /occurrences/TOC_0624/comments {body}`. Insert (author from JWT, name snapshotted) + `audit` + `outbox(COMMENT_ADDED)`. Thread is per-occurrence — tomorrow's thread is untouched.

**W7 — Upload attachment.** `POST /{owner}/{code}/attachments` (metadata) → validated (type/size) → pre-signed upload URL → client uploads to object storage → scan hook flips row `ACTIVE` → `audit(ATTACH_ADDED)`. Replace = new version, same `code`; delete = soft. Full chain reconstructable per `code`.

**W8 — Staff deactivated / roster change.** Deactivation → nightly sweep (§10.3): roster rows flip `INACTIVE`, the person's future **`TO_DO`** rows soft-delete (touched rows preserved), counters recompute, and the admin gets `ASSIGNEE_INACTIVE` — the series visibly shows "1 assignee inactive". Admin acts: add a replacement (`POST /tasks/{code}/assignees` → **backfills future `SCHEDULED` occurrences in the same transaction**), remove the roster row, or pause the series. Past/ACTIVE untouched — the June-24 history keeps Diego forever.

**W9 — Edit THIS occurrence.** `PATCH /occurrences/{code}` → `override_*` / reschedule, `is_modified=true`, cascade `occurrence_date/due_at/title` to its assignments; reschedule-into-today activates immediately; `audit`.

**W10 — Edit THIS_AND_FUTURE.** `PATCH /tasks/{code}?scope=FUTURE` → split (§12): cap old rule; cancel future `SCHEDULED` (`SERIES_SPLIT`) + cascade; new series with `parent_series_id`; materialize. Old history under the old series; lineage preserved.

**W11 — Edit ALL.** Series update + batch update of future non-exception occurrences and their assignments' read-model copies. Exceptions (`is_modified`) keep overrides.

**W12 — Pause / resume.** §7.1. Pause clears future work from My Tasks in one txn; resume regenerates assignments from the current ACTIVE roster.

**W13 — Delete / restore series.** §7.1. Delete: series + future `SCHEDULED` + `TO_DO` assignments soft-deleted in one txn; past intact. Restore: undelete + `materializeWindow` (idempotent rebuild).

**W14 — Admin views calendar.** §15.2 within the Window; §11 projection beyond; past = history rows.

**W15 — Admin generates report.** §17: bounded aggregation on `idx_assign_report`, fixed definitions, `{summary, rows}` response.

**W16 — Notification delivery.** §18: outbox → Kafka → communication-service; retries with `attempts`; dead-letter + alert past threshold.

---

# Part VI — Quality attributes

## 20. Performance and scaling

**Read strategy.** Every list = one index-only keyset scan on one table (the §7.0 invariants keep those tables truthful):

| Endpoint | Index | Scan | Joins | Profile |
|---|---|---|---|---|
| My Tasks / person view | `idx_my_tasks` | **index-only** | none | O(page), flat at any depth or history size |
| Ops board / calendar | `idx_occ_calendar` | index range | ≤ limit PK joins | O(page) |
| Series list | `idx_task_manage` + `next_occurrence_*` | index | none | O(page) |
| Occurrence detail | `UNIQUE(code)` + FK indexes | lookups | assembled | bounded by one occurrence |
| Overdue | `idx_assign_open_due` (+ `due_at < now()` in the query) | index range | — | O(page) |
| Reports | `idx_assign_report` | range + aggregate | ≤ 2 (classroom) | bounded by period |

**Write strategy.** Rollups + read-model columns are maintained by triggers/services **in the same transaction** — no async drift, and a nightly reconciliation as defense-in-depth. Every fan-out (reschedule, retitle-ALL, roster change, pause, delete) is **bounded by Window × roster** and batched — the Window is the system-wide write-amplification bound, not just a storage bound. Lock discipline: assignment→occurrence ordering; per-series advisory locks; per-series transactions sharded by school.

**Scaling path (each step has a §26 trigger):** launch scale (dozens of schools) fits a single Postgres comfortably → partition occurrence/assignment tables by month at ~few-million rows/tenant (add a routing key to cursors) → read replicas / pre-aggregates when report or read CPU demands → shard by `school_code` (already on every row and leading every index) at the far end. Note honestly: at hundreds of schools with daily series, the partitioning trigger arrives **within months** — it is a scheduled Phase-2, not a maybe.

**Caching:** none required for v1 correctness (reads are index-only). Short-TTL response caching (e.g. calendar month per user) is an optional Phase-4 optimization behind the API layer, never a source of truth.

## 21. Security and multi-tenancy

- **AuthN/Z:** JWT carries identity, role, `organization_code`/`school_code` — never trusted from the body. Clients send codes; the server resolves names from staff_service. Rate limiting owned by the API gateway (`429`).
- **Tenant isolation:** every query filters `school_code`; PostgreSQL **Row-Level Security** on each table as the database backstop — an application bug cannot leak across schools.
- **Attachments:** server-side validation, malware scan before `ACTIVE`, short-lived pre-signed URLs scoped to the school.
- **Children's data = sensitive PII:** encrypted in transit and at rest; every **write** audited in-transaction; admin bulk **reads** logged at the app layer; configurable retention (§14 retention job); zero exposure to guardian accounts (the module is invisible to parents).

## 22. RBAC and business rules

One create = series + assignee roster (+ windowed occurrences/assignments). Hierarchy depth-1, **one-off tasks only in v1**; deleting a hierarchy parent promotes children. Everything soft-deleted; all lifecycle changes obey §7.0. `scope` is visibility; the roster is assignment — a classroom-*scoped* task may be assigned to anyone. Assignees must be **staff** — guardian/parent codes are rejected server-side, not just hidden in the picker.

| Action | Admin | Staff (own) | Staff (other's) | Parent |
|---|:--:|:--:|:--:|:--:|
| Board / any person's tasks / reports | ✅ | ❌ | ❌ | ❌ |
| "My tasks" | ✅ | ✅ | — | ❌ |
| Create series + roster | ✅ | ✅ (creator) | — | ❌ |
| Edit / pause / delete / restore series | ✅ | ✅ if creator | ❌ | ❌ |
| Update own assignment (status/priority/effort) | ✅ | ✅ | ❌ | ❌ |
| Add/remove assignees (series roster or single occurrence) | ✅ | ✅ if creator | ❌ | ❌ |
| Comment (series / occurrence / own assignment) | ✅ | ✅ | ❌ | ❌ |
| Attachments on own work | ✅ | ✅ | ❌ | ❌ |
| Edit/delete others' comments | ✅ | ❌ | ❌ | ❌ |

Enforced in the service layer (source of truth); mirrored client-side only to hide affordances.

## 23. Edge-case catalog

| Case | Behavior |
|---|---|
| Duplicate scheduler run / crash mid-generation | Idempotent (`ON CONFLICT` on identity) — next run fills gaps, nothing duplicates. |
| Concurrent edits (two admins, admin+staff) | Optimistic `version` → second writer gets `409 VERSION_CONFLICT`, refetches. |
| Network retry on create | `Idempotency-Key` → original response replayed; no duplicate task. |
| Notification crash/retry | Outbox: never lost, never sent for a rollback; `attempts`-bounded retry → dead-letter + alert. |
| Staff completes future work early, then is deactivated | **Touched-work protection** — the cascade removes only `TO_DO` rows; the completed row is permanent. |
| Assignee added mid-series | Roster add backfills future `SCHEDULED` occurrences in the same transaction; past untouched. |
| Staff deactivated in staff-service | Frozen rows keep code+name snapshot; the nightly sweep flags rosters `INACTIVE`, cascades untouched future rows, and notifies the admin (§10). |
| Empty roster (all assignees removed/inactive) | Occurrence `EMPTY`, admin notified — visible staffing signal, not a silent no-op. |
| Holiday | `holiday_policy=SKIP` → `SKIPPED (HOLIDAY)` row, calendar-visible, no assignments. |
| Task postponed (reschedule) | Identity kept (`original_start_date`); assignments' dates cascade; **into today → activates immediately**. |
| Skip/cancel one date | Status change + `TO_DO` cascade; series unharmed (EXDATE semantics). |
| Series edited after six months | THIS/FUTURE/ALL semantics; exceptions survive ALL-edits; splits keep lineage (`parent_series_id`). |
| Series deleted → restored | Past intact; future soft-deleted; restore = undelete + idempotent re-materialization. |
| Pause with early-completed future work | Occurrence cancelled, `TO_DO` rows removed, completed rows preserved as history. |
| Calendar opened far in the future | Projection (§11) — display-only items, no writes. |
| Calendar opened years back | History rows (later: archived partitions, cold reads). |
| Offline edits on mobile | Optimistic Isar write + client outbox; replay on reconnect; last-write-wins on `updated_at`; comments append-only (no merge conflicts). |
| DST / school tz change | Per-date tz conversion at generation; a tz change recomputes future `due_at` on the next Window roll. |
| Back-dated series creation | Rejected (`422 BACKDATED_SERIES`); historical import is a separate admin feature (§27). |
| School merge | Out of scope for the schema; codes-on-every-row make it a bulk re-key runbook, not a redesign. |

---

# Part VII — Delivery

## 24. Clients and offline

One JSON contract; clients differ only in persistence and the offline path (mobile only).

**Flutter:** domain `Task`/`TaskOccurrence`/`TaskAssignment`/`TaskComment`/`Attachment`; cubits `TaskBoardCubit` (admin), `MyTasksCubit` (staff), `TaskDetailCubit`, `TaskCommentsCubit`; Isar collections mirror the read model (`My Tasks` rows cache as-is); Dio datasources per Appendix A; `BUILDING` renders "setting up…"; `projected:true` renders dimmed/uninteractive. **RRULE expansion is server-side only** — clients never compute occurrence dates.

**React:** React Query hooks (`useTaskBoard`, `useSeriesList`, `useOccurrence`, `useMyAssignments`, `useComments` infinite, optimistic `useUpdateAssignment`) + board/series/occurrence/thread/attachment components.

**Offline (mobile):** assignment edits & comments write optimistically with a `pending` flag into a client outbox, replayed on reconnect (`Idempotency-Key` on replays); server rollups/occurrences are authoritative on reconcile.

## 25. Rollout plan

| Phase | Backend | Mobile | Web |
|---|---|---|---|
| **1 — Core (one-off)** | `task`+`task_assignee`+`occurrence`+`assignment`, generation routine, activation job, notification outbox, screens 15.1–15.5 | split models; My Tasks, board, drill-in; create | board, drill-in, person view |
| **2 — Recurrence** | RRULE expansion, Window roll + deactivation sweep, holiday policy, edit scopes, pause/resume, projection | recurrence form, occurrence calendar (incl. projected) | recurrence UI, occurrence list |
| **3 — Comments + Attachments** | `task_comment`, `attachment`, `audit_log` CRUD | threads + composer + versioned attachments + offline outbox | threads + attachment UI |
| **4 — Notifications+ & Reports** | DUE_TODAY/OVERDUE/SERIES_ENDING events; report endpoints | in-app + push; reports | in-app; reports |

1 is the foundation; 2 depends on it; 3 parallelizes; 4 is additive.

## 26. Deferred capabilities (each with its revisit trigger)

| Deferred | Why not now | Build it when |
|---|---|---|
| Partitioning `task_occurrence`/`task_assignment` | Breaks plain `UNIQUE(code)`; launch volume modest | Tenant crosses ~few-million rows (arrives **early** at hundreds of schools — plan it as Phase-2 ops work) |
| Event-driven staff-status sync (Kafka + `sync_inbox`) | The nightly deactivation sweep reflects changes within a day — fine for *future* work | Near-real-time roster hygiene becomes a requirement |
| **Group assignment targets** (CLASSROOM/ROLE/DEPARTMENT auto-resolution) | Explicit rosters + admin-in-the-loop fit small schools; group resolution adds gRPC calls + a re-resolution job | Product commits to "assign to whoever is in X" — upgrade = `ADD COLUMN target_type DEFAULT 'USER'` on `task_assignee` + a resolution job; no schema surgery |
| Multi-stage async materialization pipeline | Idempotent windowed job is simpler and sufficient | Distributed/parallel materialization or strict recovery SLAs |
| Reporting pre-aggregates / read replica | Month-bounded live queries fine at launch | Reports slow down or contend with OLTP |
| Completion **verification** workflow (+ proof-of-completion attachment flag) | v1 completion is self-reported | Compliance demands sign-off (likely — decision §27.8) |
| Overdue escalation rules; bulk operations | Not v1-critical | Product pull |
| Elasticsearch; DB sharding; response caching | Postgres + design headroom suffices | §20 triggers |
| Custom fields (`JSONB`, never EAV); threads/mentions; checklists; templates; webhooks | No requirement yet; paths reserved | Product pull |

## 27. Open product decisions

1. **Per-person overrides at create** — priority + dates only, or effort too?
2. **Aggregate "Completed"** — all assignees, or a quorum?
3. **Comment scope default (mobile)** — occurrence thread + separate "Announcements" tab, or both inline?
4. **Comments — editable or immutable?** (Audit integrity may favor immutable + post-a-correction.)
5. **Classroom-lead visibility** — sees only their classroom's tasks? (RBAC change beyond the columns.)
6. **Holiday default** — `SKIP` (recommended) confirmed? Per-school override?
7. **Delete-day semantics** — today's `ACTIVE` occurrences remain finishable on series delete (current default) or are cancelled?
8. **Completion verification** — required for compliance tasks? If yes → Phase-4 workflow.
9. **Back-dated series** — v1 rejects; is an admin back-fill/import needed?
10. **Audit retention window** — how long for compliance?
11. **Inactive-assignee dwell time** — how long may a series carry an `INACTIVE` roster row before escalation (reminder to the admin) or automatic removal?

---

## Appendix A — API reference

Conventions in §15. Occurrence-scoped where execution is involved.

```
# Series
GET    /api/v1/tasks?view=OCCURRENCES|SERIES          # 15.2 board/calendar | 15.3 management list
POST   /api/v1/tasks                                  # W1/W2 create (+ initial Window)
GET    /api/v1/tasks/{taskCode}                       # series + rule + roster (incl. INACTIVE flags) + next-occurrence summary
PATCH  /api/v1/tasks/{taskCode}?scope=THIS|FUTURE|ALL # W9–W11
POST   /api/v1/tasks/{taskCode}/assignees             # add to roster (backfills future SCHEDULED — §10.1)
DELETE /api/v1/tasks/{taskCode}/assignees/{staffCode} # remove from roster (TO_DO cascade — §10.2)
POST   /api/v1/tasks/{taskCode}/pause | /resume       # W12
DELETE /api/v1/tasks/{taskCode}                       # W13 (soft + cascade)
POST   /api/v1/tasks/{taskCode}/restore               # W13

# Occurrences
GET    /api/v1/tasks/{taskCode}/occurrences?from&to   # materialized + projected
GET    /api/v1/occurrences/{occurrenceCode}           # 15.4 detail
PATCH  /api/v1/occurrences/{occurrenceCode}           # reschedule / override / cancel / skip

# Assignments
GET    /api/v1/occurrences/{occurrenceCode}/assignments
POST   /api/v1/occurrences/{occurrenceCode}/assignments   # manual add (is_manual_override)
PATCH  /api/v1/assignments/{assignmentCode}               # W5 status/priority/effort
DELETE /api/v1/assignments/{assignmentCode}               # manual remove (soft)
GET    /api/v1/assignments?assigneeCode=…&from&to         # 15.5 person view (admin)
GET    /api/v1/me/assignments?from&to                     # 15.1 My Tasks

# Comments / attachments / history
GET|POST     /api/v1/{owner}/{code}/comments          # owner ∈ tasks|occurrences|assignments
PATCH|DELETE /api/v1/comments/{commentCode}
POST|GET     /api/v1/{owner}/{code}/attachments       # owner ∈ tasks|occurrences|assignments|comments
PUT|DELETE   /api/v1/attachments/{attachmentCode}     # replace (new version) | soft delete
GET          /api/v1/{owner}/{code}/history           # audit timeline

# Reports
GET    /api/v1/reports/staff-performance?from&to
GET    /api/v1/reports/classroom-performance?from&to
GET    /api/v1/reports/series-compliance?taskCode&from&to
GET    /api/v1/reports/overdue
```

Representative create:

```jsonc
POST /api/v1/tasks
{ "title":"Daily classroom temperature check",
  "scope":"CLASSROOM", "classroomCode":"CLS_71731C8E",
  "recurring": true,
  "rrule": { "freq":"WEEKLY", "byDay":["MO","TU","WE","TH","FR"], "until":"2026-12-18" },
  "seriesStartDate":"2026-06-24", "seriesStartTime":"09:00", "seriesEndTime":"09:15",
  "holidayPolicy":"SKIP",
  "assignees":[ { "code":"STF_7E922B33" }, { "code":"STF_4B721F22" }, { "code":"STF_2A833D11", "priority":"HIGH" } ] }
// → 201 { success:true, data:{ code:"TSK-…", materializationStatus:"READY", occurrenceCount:22 } }
// errors: 409 VERSION_CONFLICT · 422 DUE_BEFORE_START / BACKDATED_SERIES / SUBTASK_DEPTH_EXCEEDED · …
```

## Appendix B — Worked example with dummy data

**Scenario:** "Daily classroom temperature check" — weekdays 09:00–09:15, classroom **1-Blue** (`CLS_71731C8E`). Tenant `ORG_DEMO`/`SCH_SUNNYVALE`, tz `America/Chicago`. Created 2026-06-23; Window 30 days; July 4 is a school holiday.

**B.1 Create** — staff names resolved via gRPC before the txn; one transaction writes:
```
task:   id=900 TSK_TEMPCHK … READY horizon_until=2026-07-23
roster: TAS_1 Brian Lopez · TAS_2 Diego Patel · TAS_3 Carla Chen   (all ACTIVE)
outbox: NOTIFY(TASK_ASSIGNED)      audit: TASK CREATED actor=STF_9F811C44 corr=550e…
```

**B.2 Generation** — 22 weekday occurrences inside the Window; **Jul-4 materializes as `SKIPPED (HOLIDAY)`** with no assignments; `ON CONFLICT` makes re-runs no-ops.
```
occurrences: 5001 TOC_0624 SCHEDULED · 5002 TOC_0625 SCHEDULED · … · TOC_0704 SKIPPED/HOLIDAY
assignments (occ 5001): TSA_9001 Brian · TSA_9002 Diego · TSA_9003 Carla
```

**B.3 Activation & execution (Jun-24)** — 06:00 job: 5001 → `ACTIVE`, roster frozen, DUE_TODAY sent. Brian completes 09:07 → trigger: `1/3 → aggregate_status=IN_PROGRESS`; audit records `{from:TO_DO,to:COMPLETED}`; his `assignee_name` freezes. Diego comments on the day (`CMT_1` on occurrence 5001). Jun-25 is a separate row with its own roster and empty thread.

**B.4 Staff change (Diego deactivated Jun-25; Fatima replaces him Jun-26)** — nightly sweep: roster row `TAS_2 → INACTIVE (inactive_since=2026-06-25)`, Diego's future **`TO_DO`** rows soft-deleted, `ASSIGNEE_INACTIVE` sent; the series shows "1 assignee inactive" and future occurrences roll up /2. On Jun-26 the admin adds Fatima (`POST /tasks/TSK_TEMPCHK/assignees`) → roster row inserted **and future `SCHEDULED` occurrences backfilled in the same transaction**; rollups return to /3. **Diego's Jun-24 completed work untouched** (frozen + touched-work protection). The rule never changed.

**B.5 THIS_AND_FUTURE edit (from Jul-1: start 08:30, add two staff from 2-Green)** — one txn: task 900 capped at Jun-30; future `SCHEDULED` → `CANCELLED (SERIES_SPLIT)` + `TO_DO` cascade; task 901 `TSK_TEMPCHK_V2` (`parent_series_id=900`) with the enlarged five-person roster; then `materializeWindow(901)`.

**B.6 Pause / delete / restore drill** — pause 901: future `SCHEDULED` → `CANCELLED (SERIES_PAUSED)`, `TO_DO` rows soft-deleted (My Tasks clears instantly). Resume: those rows flip back; assignments regenerate from the current ACTIVE roster. Delete: series + future + `TO_DO` cascade soft-deleted; **all past history remains**. Restore: undelete + idempotent re-materialization.

**B.7 Growth cheat sheet**

| Table | Unbounded? | Plan |
|---|---|---|
| `task`, `task_assignee` | no | — |
| `task_occurrence`, `task_assignment` | **yes** | partition at ~few-M rows/tenant (§26); archive by detaching months |
| `task_comment`, `attachment` | grows | partition later if needed; blobs in object store |
| `audit_log` | **yes** | month-partitioned from day one |
| `outbox`, `idempotency_key` | churns | prune processed/expired |

## Appendix C — New-developer orientation

**Read in this order:** §3 (concepts) → §7 (lifecycles + the two protection rules) → §6 (tables) → §8–§11 (engine) → §15 (your screen) → §23 (edge cases). Appendix B ties it together with real rows.

**The five invariants — memorize these; every bug review starts here:**
1. **Identity:** one occurrence per `(task_id, original_start_date)`; generation is idempotent (`ON CONFLICT DO NOTHING`).
2. **Cascade:** lifecycle changes reach `task_assignment` in the same transaction (the read model reads only that table).
3. **Touched work:** only `TO_DO`, non-manual rows may be removed by roster or lifecycle cascades. Facts are forever.
4. **Freeze at activation:** roster cascades touch `SCHEDULED` only; `ACTIVE`+ rosters are history.
5. **Read model at write time:** list screens read denormalized columns on one table; if you change a source field (title, dates), you cascade its copies — in the same transaction.

**Where code lives:** writes = JPA services (+ counter trigger, audit-in-txn); list reads = raw SQL/jOOQ (§15); jobs = §14; notifications = outbox only. **Never:** `OFFSET`, `now()` in an index predicate, gRPC inside a transaction, EAV, trigger-chaining onto the `task` row, client-side RRULE expansion, hard deletes.
