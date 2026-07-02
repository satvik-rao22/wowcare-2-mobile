# WowCare Tasks 2.0 — Engineering Design Document

| | |
|---|---|
| **Version** | v2.0 — post principal-architect review (lifecycles specified, holiday/pause/projection added, cascade invariant enforced) |
| **Scope** | Multi-assignee tasks with per-person tracking, recurring tasks (each occurrence separately executed), admin rollups, comments, sub-tasks, versioned attachments, full audit trail. |
| **Stack** | PostgreSQL → Spring Boot (Java) REST → Flutter (mobile) + React (web). |
| **Architecture basis** | Aligned with the approved **Events/Calendar v4** platform architecture (series/occurrence split, audience targets, outbox → Kafka → `communication-service`). Tasks extend it with a per-person **work-execution layer**, and simplify it with a **rolling materialization window** built by an **idempotent scheduled job**. |
| **Status** | Greenfield backend; mobile currently local-only. No production data → no migration risk. |

---

## Table of Contents

1. [The domain in plain language](#1-the-domain-in-plain-language)
2. [Design principles](#2-design-principles)
3. [Lifecycles — the state machines](#3-lifecycles--the-state-machines)
4. [Data model (PostgreSQL)](#4-data-model-postgresql)
5. [The recurrence engine](#5-the-recurrence-engine)
6. [Serving reads — filters, pagination, performance](#6-serving-reads--filters-pagination-performance)
7. [Security & multi-tenancy](#7-security--multi-tenancy)
8. [Business rules & RBAC](#8-business-rules--rbac)
9. [Clients & offline](#9-clients--offline)
10. [Operations](#10-operations)
11. [Rollout plan](#11-rollout-plan)
12. [Deliberately deferred](#12-deliberately-deferred)
13. [Open product decisions](#13-open-product-decisions)
- [Appendix A — API reference](#appendix-a--api-reference)
- [Appendix B — Worked example with dummy data](#appendix-b--worked-example-with-dummy-data)

---

## 1. The domain in plain language

A **task** is a unit of work in a childcare school — one-off ("plan Sports Day") or recurring ("check classroom temperature every weekday at 9"). A task can be assigned to many staff, and **each person's copy — and each recurrence — is tracked independently**: its own status, comments, attachments. Admins see each task once with a rollup; staff see only their own work; guardians see nothing.

### 1.1 Vocabulary

| Term | Meaning |
|---|---|
| **Series** (`task`) | The definition + recurrence rule. Never executed itself. A one-off task is a series that yields exactly one occurrence. |
| **Target** (`task_assignment_target`) | *Who should do it*, as intent: a USER, CLASSROOM, ROLE, or DEPARTMENT — never a hard-coded list of people. |
| **Occurrence** (`task_occurrence`) | One dated instance of the series — the executable unit. Comments/attachments/rollups per date live here. |
| **Assignment** (`task_assignment`) | One person's execution of one occurrence — status, effort, completion. The atom of work and of reporting. |
| **Window** | The rolling 60–90-day span of future occurrences kept materialized. Bounds storage *and* every write fan-out. |
| **Activation** | The daily moment an occurrence's date arrives: roster freezes, work begins. The boundary between "plan" and "fact". |
| **Projection** | Read-time RRULE expansion for dates beyond the window — display-only, no rows. |

### 1.2 Why four layers

```
   TASK (series)  ── the "what" + recurrence rule + lifecycle. Not executable.
     │
     ├── TASK_ASSIGNMENT_TARGET(s)  ── the "who" as intent (USER|CLASSROOM|ROLE|DEPARTMENT)
     │
     ▼   (engine materializes a rolling window; targets resolve to people per occurrence)
   TASK_OCCURRENCE  ── the "when": one dated instance. Rollup + per-day threads live here.
     │
     ▼
   TASK_ASSIGNMENT  ── the per-person FACT: status, effort, completion, private thread.
```

- A recurring series can't carry "done" — only a date can → execution lives on occurrence/assignment.
- Assigning to *people* breaks on turnover (edit thousands of rows when a teacher moves). Assigning to a **target** and resolving members per occurrence means the rule never changes — only classroom membership does.
- One-off = single-occurrence series → **one code path**, no `if recurring` branching.

This lets an admin see a task assigned to 100 people across 52 weeks as one series with per-occurrence rollups, gives each person independent daily state, and makes "Jane's tasks this week" one indexed query.

---

## 2. Design principles

> **Get the irreversible-later decisions right today; defer expensive machinery until metrics demand it — but reuse machinery the platform already runs.** (Notion/Figma ran single Postgres for years; their walls were operational, not query speed. We build shard-ready, not sharded.)

| # | Rule | Why |
|---|---|---|
| 1 | `school_code` on **every** table (leads every composite index) + `organization_code`. | Tenant scoping/RLS now, shard-by-tenant later. **Codes, not ids** — sibling services only have codes. |
| 2 | **Soft-delete everything**; never bulk hard-delete; keep a restore path. | A hard-delete script caused a multi-week outage at a major vendor. |
| 3 | **No EAV.** Typed columns; flexible fields (if ever) = one `JSONB` + GIN. | EAV custom-field tables are a known performance trap (Jira). |
| 4 | **Filter/sort/aggregate in SQL**; never ship all rows to the client. | Client-side board loading is a documented scaling failure (monday.com). |
| 5 | **Keyset pagination**, never `OFFSET`. | O(page) at any depth; stable under concurrent writes. |
| 6 | **Rule vs. occurrence**: recurrence is a rule; work happens on materialized occurrences (+ read-time projection beyond the window). | Pure-virtual has nowhere to hang state; full materialization explodes rows. Hybrid is the calendar/CMMS-proven answer. |
| 7 | **Read model maintained at write time.** Hot list screens read denormalized columns on one table; normalized rows stay the source of truth. | Every list = one index-only keyset scan. Denormalized fields exist **only** where a named query demands them. |
| 8 | **The cascade invariant.** Any series/occurrence lifecycle change (delete, pause, cancel, reschedule, retitle-ALL) **must cascade to its assignment rows in the same transaction.** | The read model reads *only* `task_assignment` — an un-cascaded change leaves ghost work in "My Tasks". Bounded by the window, so always cheap. |

---

## 3. Lifecycles — the state machines

*The part diagrams hide and production exposes. Every transition below has exactly one owner.*

### 3.1 Series: `series_status = ACTIVE | PAUSED | ENDED` (+ soft delete)

```
 ACTIVE ──pause──▶ PAUSED ──resume──▶ ACTIVE
   │                                     
   └──rrule exhausted / manual end──▶ ENDED
 (soft delete is orthogonal: deleted_at set; restorable)
```

| Transition | Owner | What happens (cascade invariant, one transaction) |
|---|---|---|
| **Pause** | admin/creator | Stop generation. Future `SCHEDULED` occurrences → `CANCELLED (status_reason=SERIES_PAUSED)`; their assignments soft-deleted → they vanish from My Tasks. Past/ACTIVE untouched. |
| **Resume** | admin/creator | Future `SERIES_PAUSED` occurrences flip back to `SCHEDULED`; rosters **re-resolved fresh** (membership may have changed while paused); generation resumes. |
| **End** | nightly job / admin | `rrule_until` passed or manual: no further generation. History remains. |
| **Delete** | admin/creator | Soft-delete series + future `SCHEDULED` occurrences + their assignments (same txn). **Past occurrences/assignments untouched — history is never deleted.** Today's `ACTIVE` occurrences remain finishable (default; product may flip). |
| **Restore** | admin | Clear `deleted_at` on series; re-run `materializeWindow` — idempotent generation rebuilds the window. (In-progress state on deleted future rows is not resurrected; acceptable.) |

### 3.2 Occurrence: `status = SCHEDULED | ACTIVE | CANCELLED | SKIPPED`

```
 (generated) ──▶ SCHEDULED ──daily activation job──▶ ACTIVE
                     │                                  │
                     ├─ cancel/skip (admin, holiday) ──▶ CANCELLED | SKIPPED (status_reason)
                     │
 "completed" is NOT a status — it is DERIVED (aggregate_status) from assignment counts.
```

- **Activation** (the freeze boundary): a daily job per school (start of school day, school tz) flips today's `SCHEDULED → ACTIVE`, stamps `activated_at`, and emits due-today notifications. **Re-resolution only ever touches `SCHEDULED`** — so an activated roster is frozen, and completed work can never be removed by a membership change. *(This job is the fix for the freeze gap: without it, nothing separated "plan" from "fact.")*
- `CANCELLED/SKIPPED` = the calendar EXDATE: drop one date without harming the series. Reasons: `ADMIN`, `HOLIDAY`, `SERIES_PAUSED`, `SERIES_SPLIT`. Cancelling also soft-deletes the occurrence's open assignments (invariant #8).
- Reschedule (`THIS_ONLY`): `scheduled_start_date` moves; identity `original_start_date` doesn't; child assignments' `occurrence_date/due_at` updated in the same txn.

### 3.3 Assignment: `status = TO_DO | IN_PROGRESS | COMPLETED`

- Created by resolution (or manual add, `is_manual_override=true` — never removed by re-resolution).
- `assignee_name` is a refreshable display **cache** while open; it **freezes** at terminal status → "Completed by Alice" survives Alice's resignation.
- `COMPLETED` stamps `completed_at`; the counter trigger updates the occurrence rollup in the same transaction.
- Soft-deleting an assignment (removal, cascade) is an UPDATE — **the counter trigger fires on `UPDATE OF status, deleted_at`** so counts stay exact.

### 3.4 Resolution timing (the correctness rule)

The staff service answers **current** membership only — you cannot resolve "members as of a future date". Therefore:

> **Resolve early, patch until active, freeze at activation.** Generation resolves against *today's* membership (`resolved_on = today`). The nightly job re-resolves **future `SCHEDULED`** occurrences against current membership (add joiners, remove leavers; skip `is_manual_override`). Activation freezes the roster. Past is immutable.

---

## 4. Data model (PostgreSQL)

> **Conventions.** PK `BIGINT GENERATED ALWAYS AS IDENTITY` (internal, never exposed); API exposes public `code` only. Every table: tenant (`organization_code`+`school_code`), `created_at`/`updated_at` (UTC), `version` (optimistic lock → `409`), `deleted_at`/`deleted_by`. `school_code` leads composite indexes. Times are wall-clock in the **school IANA tz**; instants (`*_at`) are UTC. Tenant/audit columns shown on core tables, elided elsewhere.

### 4.1 `task` — the series

```sql
CREATE TABLE task (
  id                BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code              VARCHAR(40)  NOT NULL UNIQUE,            -- TSK-XXXXXXXX
  organization_code VARCHAR(40)  NOT NULL,
  school_code       VARCHAR(40)  NOT NULL,
  title             VARCHAR(300) NOT NULL,
  description       TEXT         NOT NULL DEFAULT '',

  -- VISIBILITY dimension only (which board/filter shows it). Assignment is targets (§4.2).
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

  -- lifecycle (§3.1) + build flag + window marker
  series_status     VARCHAR(8)   NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE | PAUSED | ENDED
  materialization_status VARCHAR(12) NOT NULL DEFAULT 'READY',  -- READY | BUILDING (large roster only)
  horizon_until     DATE,                                    -- window materialized up to here

  -- lineage & hierarchy (two DIFFERENT relationships)
  parent_series_id  BIGINT       REFERENCES task(id),        -- THIS_AND_FUTURE split lineage
  parent_task_id    BIGINT       REFERENCES task(id) ON DELETE SET NULL,  -- sub-task, depth 1, v1: one-off only

  -- read model: series-management board reads this, O(1), no LATERAL
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
```

**Why the non-obvious keys**

| Field | Rationale |
|---|---|
| `scope`/`classroom_code` | **Visibility only** — which board/filters surface the task. It may legitimately differ from targets (a task *about* classroom 1-Blue assigned to the ROLE=NURSE). Ruling prevents the two concepts from silently conflicting. |
| `rrule_*` | Structured rule → deterministic, testable date math; shared expansion code with Events. v1 supports `until` termination only (one path to test). |
| `holiday_policy` | A school system must not generate compliance work on holidays. `SKIP` → the date materializes as `SKIPPED (HOLIDAY)` (visible on the calendar, no assignments); `KEEP` → normal. Consults the platform holiday calendar at generation. |
| `series_status` | Pause/resume is table stakes in recurring systems; soft delete is *not* pause (§3.1). |
| `materialization_status` | `READY`/`BUILDING` flag only. The window build is small and usually runs inside the create txn; `BUILDING` covers a large-roster background build. **Not** a multi-stage state machine — rejected as over-engineering for a windowed build. |
| `horizon_until` | Window marker the nightly job advances. Bounds storage and every fan-out. |
| `parent_series_id` vs `parent_task_id` | Split lineage vs sub-task hierarchy — two relationships, two columns. Hierarchy is v1-restricted to one-off tasks (sub-tasks of a *recurring* series have unclear semantics — deferred). |
| `next_occurrence_*` | Read model for the "manage series" list: each series once + next-due summary without a per-row LATERAL. Maintained by the rollup trigger/window job. |

### 4.2 `task_assignment_target` — the audience (intent, not people)

```sql
CREATE TABLE task_assignment_target (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,                          -- TGT-XXXXXXXX
  task_id BIGINT NOT NULL REFERENCES task(id) ON DELETE CASCADE,
  organization_code VARCHAR(40) NOT NULL, school_code VARCHAR(40) NOT NULL,
  target_type VARCHAR(12) NOT NULL,                          -- USER | CLASSROOM | ROLE | DEPARTMENT
  target_code VARCHAR(40) NOT NULL,
  default_priority VARCHAR(8) NOT NULL DEFAULT 'MEDIUM',
  version INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ, deleted_by VARCHAR(40)
);
CREATE INDEX idx_target_task ON task_assignment_target (task_id) WHERE deleted_at IS NULL;
```

**Why:** the turnover-proofing. The series points at `CLASSROOM=1-Blue` or `ROLE=LEAD_TEACHER`, never at named people — staff changes never touch the rule, only future resolution. A one-off "assign Jane" is the degenerate `USER` target. A series may mix targets; **if one person matches several, the first target listed wins `source_target_code`** (the unique index in §4.4 prevents duplicates; resolution must expect the conflict).

```
id | code     | task_id | target_type | target_code  | default_priority
 1 | TGT_A1B2 | 900     | CLASSROOM   | CLS_71731C8E | MEDIUM
```

### 4.3 `task_occurrence` — the dated instance

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

  status VARCHAR(12) NOT NULL DEFAULT 'SCHEDULED',           -- SCHEDULED|ACTIVE|CANCELLED|SKIPPED (§3.2)
  status_reason VARCHAR(24),                                 -- ADMIN|HOLIDAY|SERIES_PAUSED|SERIES_SPLIT
  activated_at TIMESTAMPTZ,                                  -- set by the activation job = roster freeze
  resolved_at  TIMESTAMPTZ,                                  -- last resolution run

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
);  -- NOT partitioned on day one (§12): global UNIQUE(code) = one-probe lookups
CREATE INDEX idx_occ_calendar ON task_occurrence (school_code, scheduled_start_date, aggregate_status)
  WHERE deleted_at IS NULL;
```

**Why the non-obvious keys**

| Field | Rationale |
|---|---|
| `original_start_date` vs `scheduled_start_date` | Reschedule-safe identity (Events v4 pattern): "move Monday's check to Tuesday" keeps identity, and re-running the generator can't duplicate it. |
| `UNIQUE (task_id, original_start_date)` | With `ON CONFLICT DO NOTHING` this makes generation idempotent — crash recovery, self-heal, and restore all come free. The design's keystone. |
| `activated_at` + `status=ACTIVE` | The **freeze boundary** (§3.2/§3.4). Re-resolution touches only `SCHEDULED`; completed work can never be un-assigned by a membership change. |
| `aggregate_status` GENERATED STORED | Indexable, sortable, and **cannot drift** — Postgres computes it from the counters; no second trigger. |
| `EMPTY` | Zero-member resolution is visible, not silent — surfaced to admin (an unstartable occurrence is a staffing signal). |
| not partitioned yet | Partition keys must live inside unique constraints — day-one partitioning would break plain `UNIQUE(code)` lookups. Deferred with an explicit trigger (§12). |

```
id   | code     | task_id | original_start | scheduled_start | status    | status_reason | aggregate_status
5001 | TOC_0624 | 900     | 2026-06-24     | 2026-06-24      | SCHEDULED | NULL          | NOT_STARTED
5002 | TOC_0625 | 900     | 2026-06-25     | 2026-06-25      | SCHEDULED | NULL          | NOT_STARTED
5003 | TOC_0704 | 900     | 2026-07-04     | 2026-07-04      | SKIPPED   | HOLIDAY       | EMPTY
```

### 4.4 `task_assignment` — per-person execution

```sql
CREATE TABLE task_assignment (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,                          -- TSA-XXXXXXXX
  occurrence_id BIGINT NOT NULL REFERENCES task_occurrence(id) ON DELETE CASCADE,
  organization_code VARCHAR(40) NOT NULL, school_code VARCHAR(40) NOT NULL,

  assignee_code VARCHAR(40) NOT NULL,                        -- staff_service is source of truth
  assignee_name VARCHAR(160) NOT NULL,                       -- CACHE while open; FREEZES at terminal status
  source_target_code VARCHAR(40),                            -- which target resolved this person
  resolved_on   DATE,                                        -- the date resolution RAN (not the occurrence date)
  is_manual_override BOOLEAN NOT NULL DEFAULT FALSE,         -- hand add/remove → re-resolution never touches

  -- READ MODEL (rule #7): copied so "My Tasks" is one index-only keyset scan
  occurrence_date DATE NOT NULL,                             -- = occurrence.scheduled_start_date
  due_at TIMESTAMPTZ NOT NULL,                               -- resolved due instant (school tz)
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
);  -- NOT partitioned on day one (§12)
CREATE UNIQUE INDEX uq_assign_active ON task_assignment (occurrence_id, assignee_code)
  WHERE deleted_at IS NULL;    -- one ACTIVE row per person/occurrence; re-adding a removed person works
-- the My-Tasks workhorse: filter + window + sort + display columns, ONE index → index-only scan
CREATE INDEX idx_my_tasks ON task_assignment (assignee_code, school_code, occurrence_date, id)
  INCLUDE (title, status, priority, due_at, task_code) WHERE deleted_at IS NULL;
-- overdue: partial index CANNOT contain now() (not immutable); the query supplies due_at < now()
CREATE INDEX idx_assign_open_due ON task_assignment (school_code, due_at)
  WHERE status <> 'COMPLETED' AND deleted_at IS NULL;
```

**Why the non-obvious keys**

| Field | Rationale |
|---|---|
| `occurrence_id` (not `task_id`) | Execution hangs off the occurrence → Monday's status/thread genuinely separate from Tuesday's. |
| read-model columns | Without them, "my tasks due this week sorted by date" is a cross-table join+sort with **no stable keyset cursor** — the app's most-used screen becomes its slowest. Maintained at write time; every fan-out is bounded by the window. `INCLUDE(title)` costs index size — accepted consciously for heap-free scans. |
| `resolved_on` | The date resolution *ran* (auditable: "roster as resolved on Jun 23"). Not the occurrence date — future membership is unknowable (§3.4). |
| `uq_assign_active` partial | Plain UNIQUE would block re-adding a previously removed person (soft-deleted row collides). Classic missed bug. |
| counter trigger | Fires on `INSERT` and `UPDATE OF status, deleted_at` (soft delete must decrement). Lock order is always *assignment → occurrence* to prevent deadlocks. |

```
id   | code     | occ  | assignee     | assignee_name | source   | resolved_on | status      | completed_at
8001 | TSA_9001 | 5001 | STF_7E922B33 | Brian Lopez   | TGT_A1B2 | 2026-06-23  | COMPLETED   | 06-24 09:07
8002 | TSA_9002 | 5001 | STF_4B721F22 | Diego Patel   | TGT_A1B2 | 2026-06-23  | IN_PROGRESS | NULL
8003 | TSA_9003 | 5001 | STF_2A833D11 | Carla Chen    | TGT_A1B2 | 2026-06-23  | TO_DO       | NULL
→ occurrence 5001: total=3, completed=1, in_progress=1 → aggregate_status=IN_PROGRESS
```

### 4.5 `task_comment` — three scopes, exactly one target

```sql
CREATE TABLE task_comment (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE, school_code VARCHAR(40) NOT NULL,
  task_id            BIGINT REFERENCES task(id)            ON DELETE CASCADE,  -- series announcement
  task_occurrence_id BIGINT REFERENCES task_occurrence(id) ON DELETE CASCADE,  -- one day's thread
  task_assignment_id BIGINT REFERENCES task_assignment(id) ON DELETE CASCADE,  -- private 1:1 thread
  author_code VARCHAR(40) NOT NULL, author_name VARCHAR(160) NOT NULL,         -- snapshot, never refreshed
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

Series note ("always use the wall thermometer") / day thread ("reading was high, escalated") / private thread ("out sick, Carla covers"). Comments on occurrences later cancelled by a split stay attached to the CANCELLED row — the UI renders them as historical. *Editable vs immutable: open decision §13.*

### 4.6 `attachment` — versioned, full add/replace/delete history

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

Add → v1. Replace → new row, same `code`, `version+1`, prior `is_current=false` (blob retained → revision chain). Delete → soft; blob kept for restore, expired by storage lifecycle. DB stores keys only; access via short-lived pre-signed URLs; server-side type/size validation + malware scan before `ACTIVE`. Every action audited.

### 4.7 `audit_log` — compliance history (month-partitioned)

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

Written **in the same transaction** as the mutation — history can never disagree with state. Old months detach & archive (metadata op, not a giant DELETE).

### 4.8 Reliability spine: `outbox` / `idempotency_key` (platform pattern)

```sql
CREATE TABLE outbox (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  aggregate_type VARCHAR(24) NOT NULL, aggregate_code VARCHAR(40) NOT NULL,
  event_type VARCHAR(40) NOT NULL,           -- NOTIFY_ASSIGNEES|DUE_SOON|OVERDUE|SERIES_ENDING|…
  school_code VARCHAR(40) NOT NULL, payload JSONB NOT NULL,
  status VARCHAR(12) NOT NULL DEFAULT 'PENDING', attempts INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), processed_at TIMESTAMPTZ
);
CREATE TABLE idempotency_key (
  key UUID PRIMARY KEY, school_code VARCHAR(40) NOT NULL,
  response_code INT, response_body JSONB, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

- **`outbox` is for notifications only** (crash-safe: committed with the business change, relayed to Kafka `notification-events`, delivered by `communication-service`; never lost, never sent for a rollback). Materialization does **not** use it.
- `idempotency_key`: a retried POST returns the original response, never a duplicate task.
- `sync_inbox` (Kafka consumer dedup) is **deferred** with event-driven membership sync (§12); v1's nightly batch needs neither.

---

## 5. The recurrence engine

### 5.1 `materializeWindow` — one idempotent routine

Called (a) at create for the initial window and (b) nightly to roll forward + self-heal. **Membership is resolved via gRPC *before* the transaction opens** — remote calls inside an open transaction hold locks hostage to network latency.

```
routine materializeWindow(task, fromDate, toDate):
  members  := resolveTargets(task.targets)                  -- gRPC OUTSIDE any txn (current membership)
  holidays := holidayCalendar(school, fromDate..toDate)     -- platform service, read before txn

  BEGIN TX (advisory lock on task.id)                       -- serializes vs splits & re-resolution
    for each rule-date D in expandRRULE(task, fromDate, toDate):
      if D in holidays and task.holiday_policy = 'SKIP':
        INSERT task_occurrence (…, D, status='SKIPPED', status_reason='HOLIDAY')
          ON CONFLICT (task_id, original_start_date) DO NOTHING       -- no assignments
      else:
        occ := INSERT task_occurrence (…, D, status='SCHEDULED')
                 ON CONFLICT (task_id, original_start_date) DO NOTHING
        if newly inserted:
          INSERT task_assignment (occ, m, source_target_code, resolved_on=today,
                                  occurrence_date=D, due_at, title, task_code)  for m in members
          if members is empty → audit(OCCURRENCE_EMPTY) + admin notification via outbox
    task.horizon_until := toDate;  refresh task.next_occurrence_*
  COMMIT
```

- **Recovery = idempotency, not a state machine.** A crashed/re-run job fills gaps; nothing double-generates. This also makes **restore-after-delete** nearly free.
- **One transaction per series, jobs sharded by school** — never a global mega-transaction.
- WINDOW = **60–90 days** (configurable). It bounds storage *and* the blast radius of every fan-out (membership change, reschedule, retitle).
- Create: small roster → runs inside the create txn (task is `READY` immediately, `201` returns `occurrenceCount`); large roster → quick background build, `BUILDING → READY`.
- Series with a **past** `series_start_date`: v1 **rejects** back-dated creation (422); back-filling history is an explicit admin import feature if ever needed (open decision §13).

### 5.2 Daily activation job (the freeze boundary)

Per school, at start of school day (school tz): flip today's `SCHEDULED → ACTIVE`, stamp `activated_at`, enqueue due-today notifications. Re-resolution (§5.3) only touches `SCHEDULED` → activated rosters are frozen; completed work is untouchable by membership changes.

### 5.3 Nightly membership re-resolution (future only)

While rolling the window, re-resolve each **future `SCHEDULED`** occurrence against current membership: add joiners, soft-delete leavers' open rows (`is_manual_override` rows never touched), update `resolved_on`, recompute counters. Past/ACTIVE/terminal rows are never modified — history is what actually happened. *(Event-driven near-real-time sync via Kafka + `sync_inbox` is the deferred upgrade — §12.)*

### 5.4 Virtual projection — the calendar beyond the window

Materialized rows exist only inside the window, but users page calendars further ahead. Reads past `horizon_until` **merge materialized rows with projected ones** — computed from the RRULE at read time:

```jsonc
{ "date":"2026-11-16", "title":"Daily classroom temperature check",
  "projected": true }               // no code, no assignments, display-only
```

Projection is a pure function of the rule (plus holiday calendar) — no writes from reads, infinite forward navigation, and the window still bounds all real rows. (This is exactly how calendar products render "forever" without storing it.)

### 5.5 Edit scopes

| Scope | Mechanics |
|---|---|
| **THIS_ONLY** | Update the one occurrence (`override_*`/reschedule, `is_modified=true`); cascade `occurrence_date/due_at/title` to its assignments (same txn). ALL-edits never clobber `is_modified` rows. |
| **THIS_AND_FUTURE** | **Series split** (one txn): cap old series (`rrule_until = day-1`), `CANCEL (SERIES_SPLIT)` its future SCHEDULED occurrences + soft-delete their assignments (invariant #8), insert new series (`parent_series_id` = old), materialize it. |
| **ALL** | Update series; batch-update future non-exception occurrences + their assignments' read-model copies (bounded by window); exceptions keep overrides. |
| **CANCEL/SKIP one** | Occurrence `status` change + assignment soft-delete cascade. Never a hard delete. |

### 5.6 Pause / resume / delete / restore

Defined in §3.1. Implementation notes: pause's `CANCELLED (SERIES_PAUSED)` rows **block** `ON CONFLICT` regeneration by design — resume flips exactly those rows back to `SCHEDULED` and re-resolves rosters fresh, reusing existing machinery. Restore = clear `deleted_at` + `materializeWindow` (idempotent).

---

## 6. Serving reads — filters, pagination, performance

**Write/read split.** Writes via JPA/services (transactions; triggers keep rollups + read model true). **List reads via raw SQL/jOOQ on the read-model columns** — never ORM graph traversal. Invariant: **every list endpoint = one index-only, keyset-paginated scan on one table.**

**Conventions.** Envelope `{success,message,data}`; errors `400/401/403/404/409/422/429`; `version`/`If-Match` → `409`; `Idempotency-Key` on creates; identity/tenant from JWT only; names resolved server-side (clients send codes). Sorting = curated allow-list per endpoint, each option index-backed; enum sorts use `*_rank`.

### 6.1 Filters (server-side, indexed)

| Filter | Driving column | Mechanism |
|---|---|---|
| status | `assignment.status` / `occurrence.aggregate_status` | equality on indexed/generated column |
| priority | `assignment.priority_rank` | ordinal equality/range |
| assignee | `assignment.assignee_code` | index lead |
| classroom/scope | `task.scope`, `task.classroom_code` | board filter (visibility dimension) |
| date range | `occurrence.scheduled_start_date` / `assignment.occurrence_date` | range on the index sort key; **a window is mandatory server-side** (defaulted if omitted — no unbounded scans) |
| overdue | derived | index `(school_code, due_at) WHERE status<>'COMPLETED'`; the **query** supplies `due_at < now()` (never stored, never in an index predicate) |
| text search | `title` | `ILIKE`/trigram now; GIN when hot (§12) |

### 6.2 Pagination — keyset

Order by `(sortKey, id)`; cursor = last row's tuple, base64, opaque. `WHERE (sortKey,id) > (:cur…) LIMIT n` → **O(page) at any depth**, stable under inserts. Response carries `nextCursor` (null at end). No `OFFSET`, no totals.

### 6.3 Worked example — Staff "My Tasks"

```
GET /api/v1/me/assignments?from=2026-06-22&to=2026-06-28&status=TO_DO&limit=20
Authorization: Bearer <jwt: staff=STF_7E922B33, school=SCH_SUNNYVALE>
```
```java
var rows = jdbc.query("""
   SELECT code, task_code, title, occurrence_date, due_at, status, priority
     FROM task_assignment
    WHERE assignee_code = :me AND school_code = :school AND deleted_at IS NULL
      AND occurrence_date BETWEEN :from AND :to
      AND (:status IS NULL OR status = :status)
      AND (:curDate IS NULL OR (occurrence_date, id) > (:curDate, :curId))
    ORDER BY occurrence_date, id
    LIMIT :limit""", params, MyTaskRow::map);
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
**Performance:** one **index-only scan** on `idx_my_tasks` — no joins, no heap fetch, no sort. Flat latency at any history size or page depth. *Only possible because the read-model columns live on the assignment* — and only trustworthy because of cascade invariant #8 (deleted/paused series vanish from this index in the same transaction that changes them).

### 6.4 Worked example — Admin board (occurrence-windowed)

```
GET /api/v1/tasks?from=2026-06-22&to=2026-06-28&status=IN_PROGRESS&limit=20
```
```sql
SELECT o.code, COALESCE(o.override_title, t.title) AS title, o.scheduled_start_date,
       o.aggregate_status, o.assignment_total, o.assignment_completed, o.status, o.status_reason
  FROM task_occurrence o
  JOIN task t ON t.id = o.task_id                       -- ≤ LIMIT primary-key joins
 WHERE o.school_code = :school AND o.deleted_at IS NULL
   AND o.scheduled_start_date BETWEEN :from AND :to
   AND (:status IS NULL OR o.aggregate_status = :status)
   AND (:cur IS NULL OR (o.scheduled_start_date, o.id) > (:curDate, :curId))
 ORDER BY o.scheduled_start_date, o.id LIMIT :limit;
```
**Performance:** index range scan on `idx_occ_calendar` + ≤limit PK joins; keyset → O(page). A recurring task appears **once per due date** (an ops board). SKIPPED/HOLIDAY rows render as calendar context. The "manage series" list reads `task.next_occurrence_*` → O(1) per series, no join. Beyond `horizon_until`, results merge **projected** items (§5.4).

### 6.5 Worked example — Occurrence detail (past or future — same query)

`GET /api/v1/occurrences/TOC_0624` → four bounded index lookups, assembled: occurrence by global `UNIQUE(code)`, its assignments (frozen if past), first comment page (`idx_comment_occ`, keyset for more), current attachments. A **past** occurrence is identical — assignments are frozen history, names locked at completion. Archived partitions (when partitioning lands) serve cold reads with higher latency — acceptable, stated.

### 6.6 Performance matrix

| Endpoint | Index | Scan | Joins | Pagination | Profile |
|---|---|---|---|---|---|
| My Tasks / by-person | `idx_my_tasks` | **index-only** | none | keyset `(occurrence_date,id)` | O(page), flat |
| Admin board | `idx_occ_calendar` | index range | ≤limit PK | keyset `(scheduled_start_date,id)` | O(page) |
| Series-manage list | `task` + `next_occurrence_*` | index | none | keyset | O(page) |
| Occurrence detail | `UNIQUE(code)` + FKs | lookups | assembled | comments keyset | bounded by one occurrence |
| Overdue | `idx_assign_open_due` (+ `due_at < now()` in query) | index range | — | keyset | O(page) |

**Write-side profile:** every fan-out (reschedule, retitle-ALL, membership change, pause, delete) is **bounded by the window × roster** and batched in one transaction — the rolling window is the system-wide write-amplification bound, not just a storage bound.

---

## 7. Security & multi-tenancy

- **AuthN/Z:** JWT carries identity, role, `organization_code`/`school_code` — never trusted from the body. Names resolved from staff_service; clients send codes only. Rate limiting owned by the API gateway (`429`).
- **Tenant isolation:** every query filtered by `school_code`; Postgres **Row-Level Security** per table as the DB backstop.
- **Attachments:** server-side type/size validation; malware scan before `ACTIVE`; short-lived pre-signed URLs scoped to the school.
- **Children's data = sensitive PII:** encrypt in transit/at rest; every **write** audited in-transaction; admin bulk **reads** logged at the app layer; configurable retention (§10); zero exposure to guardian accounts.

---

## 8. Business rules & RBAC

One create = series + targets (+ windowed occurrences/assignments). Hierarchy depth-1, **one-off tasks only in v1**. Deleting a hierarchy parent promotes children. Everything soft-deleted; lifecycle changes obey cascade invariant #8. `scope` is visibility; targets are assignment — they may differ by design.

| Action | Admin | Staff (own) | Staff (other's) | Parent |
|---|:--:|:--:|:--:|:--:|
| Board / any person's tasks | ✅ | ❌ | ❌ | ❌ |
| "My tasks" | ✅ | ✅ | — | ❌ |
| Create series + targets | ✅ | ✅ (creator) | — | ❌ |
| Edit / pause / delete series | ✅ | ✅ if creator | ❌ | ❌ |
| Update own assignment (status/priority/effort) | ✅ | ✅ | ❌ | ❌ |
| Manual add/remove person on an occurrence | ✅ | ✅ if creator | ❌ | ❌ |
| Comment (series / occurrence / own assignment) | ✅ | ✅ | ❌ | ❌ |
| Attachments (add/replace/delete) | ✅ | ✅ on own | ❌ | ❌ |
| Edit/delete others' comments | ✅ | ❌ | ❌ | ❌ |

---

## 9. Clients & offline

One JSON contract; clients differ only in persistence + the offline path (mobile).

**Flutter:** domain `Task`/`TaskOccurrence`/`TaskAssignment`/`TaskComment`/`Attachment`; cubits `TaskBoardCubit` (admin), `MyTasksCubit` (staff), `TaskDetailCubit`, `TaskCommentsCubit`; Isar collections per entity; Dio datasources; `BUILDING` renders "setting up…"; `projected:true` items render dimmed/uninteractive.

**React:** React Query hooks (`useTaskBoard`, `useSeriesDetail`, `useOccurrence`, `useMyAssignments`, `useComments` infinite, optimistic `useUpdateAssignment`) + board/occurrence/assignee/thread/attachment components.

**Offline (mobile):** assignment edits & comments write optimistically to Isar (`pending` flag) + client outbox, replayed on reconnect; last-write-wins on `updated_at`; comments append-only (no merge conflicts). Rollups/occurrences are server-authoritative (server wins on reconcile). **RRULE expansion is server-side only** — clients never compute occurrence dates.

---

## 10. Operations

**Scheduled jobs** (all per-school sharded, per-series transactions, advisory-locked):

| Job | When | Does |
|---|---|---|
| Window roll | nightly | `materializeWindow(horizon_until+1 … today+WINDOW)` per active series; marks `ENDED` when rule exhausted; refreshes `next_occurrence_*` |
| Membership re-resolution | nightly (same pass) | re-resolve future `SCHEDULED` rosters (§5.3) |
| Activation | daily, school-day start (school tz) | `SCHEDULED→ACTIVE` for today + due-today notifications (§5.2) |
| Reconciliation | nightly | recompute counters from source; alert on drift |
| Retention | monthly | detach/archive old `audit_log` partitions; purge soft-deleted rows + orphaned blobs past grace period |

**Migrations:** Flyway, forward-only, additive. **Backups:** PITR + restore drills; soft-delete + retained blobs = app-level undo. **Observability (the dials that fire the §12 triggers):** per-tenant row counts, job failures + series stuck `BUILDING`, outbox lag/`attempts`, counter drift, slow-query log, `EMPTY` occurrence rate. A named owner watches them — a scalable design with nobody watching the dials just fails slower.

---

## 11. Rollout plan

| Phase | Backend | Mobile | Web |
|---|---|---|---|
| **1 — Core (one-off)** | `task`+`target`+`occurrence`+`assignment`, generation routine, activation job, notification outbox, board/detail/me/person reads | split models; board, my-tasks, drill-in; create | board, drill-in, person view |
| **2 — Recurrence** | RRULE expansion, window roll + re-resolution jobs, holiday policy, edit scopes, pause/resume, projection | recurrence form, occurrence calendar (incl. projected) | recurrence UI, occurrence list |
| **3 — Comments + Attachments** | `task_comment`, `attachment`, `audit_log` CRUD | threads + composer + versioned attachments + offline outbox | threads + attachment UI |
| **4 — Notifications+** | due-soon / overdue / series-ending events; escalation hooks | in-app + push | in-app |

1 is the foundation; 2 depends on it; 3 parallelizes; 4 is additive.

---

## 12. Deliberately deferred (each with its revisit trigger)

| Deferred | Why now | Revisit when |
|---|---|---|
| **Partitioning** `task_occurrence`/`task_assignment` | Global `UNIQUE(code)` = one-probe lookups; launch volume modest. *Note: at hundreds of schools with daily series this trigger arrives within months — it's a scheduled Phase-2, not a maybe.* | Either table crosses a few million rows → partition by date + routing key in cursors. |
| **Event-driven membership sync** (Kafka consumer + `sync_inbox`) | Nightly batch reflects changes in future occurrences within a day — they're *future*. | Near-real-time future rosters become a product requirement. |
| **Multi-stage async materialization pipeline** | Idempotent windowed job is simpler and sufficient; generation isn't latency-sensitive. | Distributed/parallel materialization or strict recovery SLAs. |
| **DB sharding** | Single Postgres serves for years; tenant keys make it mechanical later. | A table nears billions of rows / vertical ceiling. |
| **Elasticsearch** | Postgres trigram/FTS suffices. | A tenant > ~1M rows with complex multi-field search. |
| **Reporting pre-aggregates / replica** | Live queries fine at launch; classroom grouping = 3-table join, tolerable. | Monthly/yearly reports slow down or contend with OLTP. |
| **Completion verification workflow** (staff completes → admin verifies) | v1 completion is self-reported. | Compliance/audit demands sign-off (likely — see §13). |
| **`rrule_count`, custom fields, threads/mentions, checklists, templates, webhooks** | Not required yet; JSONB path reserved (never EAV). | Product pull. |

---

## 13. Open product decisions

1. **Per-person overrides at create** — priority + dates only, or effort too?
2. **Aggregate "Completed"** — all assignees, or a quorum?
3. **Comment scope default (mobile)** — occurrence thread + separate "Announcements" tab, or both inline?
4. **Comments — editable or immutable?** (audit integrity may favor immutable + post-a-correction.)
5. **Classroom-lead visibility** — sees only their classroom's tasks? (RBAC change beyond the columns.)
6. **Holiday default** — `SKIP` (recommended) confirmed? Per-school override?
7. **Delete-day semantics** — today's `ACTIVE` occurrences remain finishable on series delete (current default) or are cancelled?
8. **Completion verification** — needed for compliance tasks (temperature/medication checks)? If yes → Phase-4 workflow + proof-of-completion attachment flag.
9. **Back-dated series** — rejected in v1; is an admin back-fill/import needed?
10. **Audit retention window** — how long for compliance?
11. **Forward-roster projection** — show projected assignee names on SCHEDULED/projected occurrences, or just the target label ("1-Blue teachers")?

---

## Appendix A — API reference

Conventions in §6. Occurrence-scoped where execution is involved.

```
# Series
GET    /api/v1/tasks                                  # occurrence-windowed board (mandatory/defaulted window)
POST   /api/v1/tasks                                  # create series + targets (+ initial window)
GET    /api/v1/tasks/{taskCode}                       # series + rule + targets + next-occurrence summary
PATCH  /api/v1/tasks/{taskCode}?scope=THIS|FUTURE|ALL # edit (scope semantics §5.5)
POST   /api/v1/tasks/{taskCode}/pause | /resume       # series lifecycle (§3.1)
DELETE /api/v1/tasks/{taskCode}                       # soft delete + cascade (§3.1)
POST   /api/v1/tasks/{taskCode}/restore               # undelete + rematerialize

# Occurrences
GET    /api/v1/tasks/{taskCode}/occurrences?from&to   # materialized + projected (beyond horizon)
GET    /api/v1/occurrences/{occurrenceCode}           # detail: rollup + assignments + comments + attachments
PATCH  /api/v1/occurrences/{occurrenceCode}           # reschedule / THIS_ONLY override / cancel / skip

# Assignments
GET    /api/v1/occurrences/{occurrenceCode}/assignments
POST   /api/v1/occurrences/{occurrenceCode}/assignments   # manual add (is_manual_override)
PATCH  /api/v1/assignments/{assignmentCode}               # status/priority/effort
DELETE /api/v1/assignments/{assignmentCode}               # manual remove (soft)
GET    /api/v1/assignments?assigneeCode=…&from&to         # person view (admin)
GET    /api/v1/me/assignments?from&to                     # My Tasks

# Comments / attachments / history
GET|POST     /api/v1/{owner}/{code}/comments          # owner ∈ tasks|occurrences|assignments
PATCH|DELETE /api/v1/comments/{commentCode}
POST|GET     /api/v1/{owner}/{code}/attachments       # owner ∈ tasks|occurrences|assignments|comments
PUT|DELETE   /api/v1/attachments/{attachmentCode}     # replace (new version) | soft delete
GET          /api/v1/{owner}/{code}/history           # audit timeline
```

Representative payloads:

```jsonc
POST /api/v1/tasks
{ "title":"Daily classroom temperature check",
  "scope":"CLASSROOM", "classroomCode":"CLS_71731C8E",
  "recurring": true,
  "rrule": { "freq":"WEEKLY", "byDay":["MO","TU","WE","TH","FR"], "until":"2026-12-18" },
  "seriesStartDate":"2026-06-24", "seriesStartTime":"09:00", "seriesEndTime":"09:15",
  "holidayPolicy":"SKIP",
  "targets":[ { "type":"CLASSROOM", "code":"CLS_71731C8E", "defaultPriority":"MEDIUM" } ] }
// → 201 { success:true, data:{ code:"TSK-…", materializationStatus:"READY", occurrenceCount:22 } }

PATCH /api/v1/assignments/{code}   { "status":"COMPLETED" }
// → 200 { data:{ code:"TSA-…", status:"COMPLETED", completedAt:"…", version:1 } }
//   (occurrence rollup + aggregate_status recompute in the same transaction)

// errors: 409 VERSION_CONFLICT · 422 DUE_BEFORE_START / BACKDATED_SERIES / SUBTASK_DEPTH_EXCEEDED · …
```

---

## Appendix B — Worked example with dummy data

**Scenario:** "Daily classroom temperature check" — weekdays 09:00–09:15, classroom **1-Blue** (`CLS_71731C8E`). Tenant `ORG_DEMO`/`SCH_SUNNYVALE`, tz `America/Chicago`. Created 2026-06-23; window 30 days; July 4 is a school holiday.

### B.1 Create

```
task:  id=900 code=TSK_TEMPCHK title='Daily classroom temperature check'
       scope=CLASSROOM classroom_code=CLS_71731C8E
       recurring_flag=true rrule_freq=WEEKLY rrule_by_day='MO,TU,WE,TH,FR' rrule_until=2026-12-18
       holiday_policy=SKIP series_status=ACTIVE materialization_status=READY horizon_until=2026-07-23
target: id=1 code=TGT_A1B2 task_id=900 CLASSROOM CLS_71731C8E MEDIUM
outbox: NOTIFY_ASSIGNEES (PENDING)          audit_log: TASK CREATED actor=STF_9F811C44 corr=550e…
```
Members (Brian, Diego, Carla) were resolved via gRPC **before** the transaction; the 30-day window was generated inside it (small roster → `READY` immediately).

### B.2 Generation

22 weekday dates expand; **Jul-4 materializes as `SKIPPED (HOLIDAY)`** with no assignments. `ON CONFLICT (task_id, original_start_date) DO NOTHING` → re-runs are no-ops.

```
task_occurrence: 5001 TOC_0624 2026-06-24 SCHEDULED · 5002 TOC_0625 2026-06-25 SCHEDULED · … · 50xx TOC_0704 SKIPPED/HOLIDAY
task_assignment (occ 5001): TSA_9001 Brian · TSA_9002 Diego · TSA_9003 Carla   (resolved_on=2026-06-23, src=TGT_A1B2)
```

### B.3 Activation & execution — Jun-24

06:00 activation job: occurrence 5001 `SCHEDULED→ACTIVE`, `activated_at` stamped, due-today notifications sent. **Roster now frozen.**
Brian completes at 09:07:
```
PATCH /assignments/TSA_9001 {status:COMPLETED}
→ TSA_9001 status=COMPLETED completed_at=09:07 version=1  (assignee_name freezes)
→ trigger: occ 5001 total=3 completed=1 → aggregate_status=IN_PROGRESS
→ audit_log: ASSIGNMENT STATUS_CHANGED {"status":{"from":"TO_DO","to":"COMPLETED"}}
```
Diego comments on the day: `task_comment CMT_1 (task_occurrence_id=5001) 'Thermometer battery low'`.
Jun-25 (occ 5002) is a separate row with its own roster and empty thread — untouched.

### B.4 Staff change — Diego leaves, Fatima joins 1-Blue on Jun-26

Nightly job (Jun-25 18:00) re-resolves **future `SCHEDULED`** occurrences of series 900:
```
occ 5003+ : + TSA Fatima (TO_DO, resolved_on=2026-06-25)   − Diego's open rows soft-deleted, counters recomputed
occ 5001  : ACTIVE  → untouched (Diego's Jun-24 work is frozen history)
occ 5002  : already ACTIVE by the time of the next roll → frozen
```
The rule never changed; only future rosters did.

### B.5 Edit THIS_AND_FUTURE — from Jul-1, start 08:30 and add classroom 2-Green

```
PATCH /tasks/TSK_TEMPCHK?scope=FUTURE {seriesStartTime:'08:30', addTarget:{CLASSROOM CLS_E2618D09}}
one txn: task 900 rrule_until=2026-06-30 · future SCHEDULED occs → CANCELLED(SERIES_SPLIT) + assignments soft-deleted
         task 901 TSK_TEMPCHK_V2 (parent_series_id=900, 08:30, until=2026-12-18) + both targets
then:    materializeWindow(901) → occurrences for both classrooms from Jul-1
```

### B.6 Pause / delete / restore (lifecycle drill)

- **Pause 901** → future SCHEDULED → `CANCELLED(SERIES_PAUSED)`, assignments soft-deleted (My Tasks clears instantly — cascade invariant). **Resume** → those rows flip back to `SCHEDULED`, rosters re-resolved fresh.
- **Delete 901** → series + future SCHEDULED occurrences + assignments soft-deleted in one txn; **all past history remains** queryable and calendar-visible.
- **Restore 901** → `deleted_at` cleared, `materializeWindow` rebuilds the window idempotently.

### B.7 Growth & archival cheat sheet

| Table | Unbounded growth? | Plan |
|---|---|---|
| `task`, `task_assignment_target` | no | — |
| `task_occurrence`, `task_assignment` | **yes** | partition when a tenant crosses ~few M rows (§12); archive by detaching months |
| `task_comment`, `attachment` | grows | partition later if needed; blobs live in object store |
| `audit_log` | **yes** | month-partitioned from day one |
| `outbox` / `idempotency_key` | churns | prune processed/expired rows |

*No local notification table — delivery is `communication-service` via Kafka, fed by the transactional outbox.*
