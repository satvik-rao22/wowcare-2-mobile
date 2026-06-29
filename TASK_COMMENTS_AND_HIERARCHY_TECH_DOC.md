# WowCare Tasks 2.0 — System Design

| | |
|---|---|
| **Scope** | Redesign of the Tasks module: multi-assignee tasks with per-person tracking, an admin rollup view, task comments, task hierarchy (sub-tasks), attachments with full history, and an audit trail. |
| **Stack** | PostgreSQL → Spring Boot (Java) REST API → two clients: Flutter (mobile) + React (web). |
| **Status** | Greenfield backend. Mobile currently runs local-only (Isar + bundled mock data); no production data exists, so this can be built correctly with no migration risk. |
| **Audience** | Engineering (backend, web, mobile) + technical review. |

---

## Table of Contents

1. [Overview](#1-overview)
2. [Guiding principles](#2-guiding-principles)
3. [Core model: Task + Assignment](#3-core-model-task--assignment)
4. [Data model (PostgreSQL)](#4-data-model-postgresql)
5. [Derived data: counters, rollups, overdue, time zones](#5-derived-data-counters-rollups-overdue-time-zones)
6. [API design](#6-api-design)
7. [The admin & staff views](#7-the-admin--staff-views)
8. [Security & multi-tenancy](#8-security--multi-tenancy)
9. [Business rules & RBAC](#9-business-rules--rbac)
10. [Client integration](#10-client-integration)
11. [Offline & sync (mobile)](#11-offline--sync-mobile)
12. [Operations](#12-operations)
13. [Rollout plan](#13-rollout-plan)
14. [Deliberately deferred (with rationale)](#14-deliberately-deferred-with-rationale)
15. [Open product decisions](#15-open-product-decisions)
- [Appendix A — Complete API reference](#appendix-a--complete-api-reference)

---

## 1. Overview

A **task** is a unit of work in a childcare school. A task can be **school-wide or scoped to a classroom**, and can be assigned to **many staff members**, with **each person's copy tracked independently** — its own status, priority, start/due dates and effort. The system serves three needs:

- **Admins** see each task **once**, with a rolled-up view of how all assignees are progressing, and can drill into any one person.
- **Staff** see only their **own** work items, exactly as a personal to-do list.
- Tasks support **discussion (comments)**, **sub-tasks (hierarchy)**, **attachments with full revision history**, and a complete **audit trail** for compliance.

Guardians/parents have **no access** to the module.

---

## 2. Guiding principles

Built on clean architecture (`presentation → domain → data`), consistent with the existing codebase, plus a deliberate scaling philosophy:

> **Get the irreversible-later decisions right today; defer the expensive machinery until real metrics demand it.** Large task systems (Notion, Figma) ran a single PostgreSQL instance for years before sharding — and the wall they eventually hit was operational (VACUUM, transaction-ID wraparound), not query speed. WowCare is far smaller, so we build **shard-ready, not sharded.**

**Seven rules adopted from day one** (cheap now, painful to retrofit):

| # | Rule | Rationale |
|---|---|---|
| 1 | `school_code` on **every** table (leading every composite index), plus `organization_code` for cross-service consistency. | A school belongs to one org, so `school_code` alone scopes & shards data; `organization_code` matches staff_service et al. and enables org-level rollups. Enables RLS now, shard-by-tenant later, no model change. |
| 2 | **Soft-delete** everything (`deleted_at`, `deleted_by`); never bulk hard-delete; keep a restore path. | A hard-delete maintenance script caused a multi-week data-loss outage at a major vendor. |
| 3 | **No EAV.** Task fields are typed columns; flexible fields (if ever) use one `JSONB` column + GIN index — never a `field_values` table. | EAV custom-field tables are a well-known query/index performance trap. |
| 4 | **Filter, sort and aggregate in SQL**, never by shipping all rows to the client. | Loading whole boards client-side is a documented scaling failure mode. |
| 5 | **Keyset (cursor) pagination**, not `OFFSET`. | `OFFSET` degrades linearly on deep pages. |
| 6 | **Append-only history** (`audit_log`) is its own time-partitioned table. | It is the one table that only ever grows; partitioning makes archival a metadata operation. |
| 7 | **PostgreSQL does search** (trigram / `tsvector`) until a tenant exceeds ~1M rows with complex filters. | An external search engine is operational overhead we don't yet need. |

---

## 3. Core model: Task + Assignment

The central decision. A multi-assignee task is **two levels**, not N independent copies:

- **Task** — the *definition* (the "what"), created once: title, description, scope, recurrence, hierarchy link.
- **Task Assignment** — the *per-person instance* (the "who + their progress"): assignee, status, priority, start/due, effort. **One row per assignee.**

```
                 ┌──────────────────────────────┐
            ┌───▶│            TASK              │  defined ONCE
            │    │  title, description, scope,  │  (TSK-…)
            │    │  recurrence, parent_task_id  │
            │    └───────────────┬──────────────┘
   parent   │                    │ 1 : N
  (depth 1) │                    ▼
            │    ┌──────────────────────────────┐
            └────│       TASK_ASSIGNMENT        │  one row PER PERSON (TSA-…)
                 │  assignee, status, priority, │  individually editable
                 │  start/due, effort, …        │
                 └──────────────────────────────┘
```

This is what lets an admin see a task assigned to 100 people as **one row with a rollup**, lets each person carry different dates/priority, and makes "all tasks assigned to Jane" a simple indexed query on assignments.

---

## 4. Data model (PostgreSQL)

> Conventions: internal PK is `BIGINT GENERATED ALWAYS AS IDENTITY` (never exposed); the API exposes only the public `code`. Every table carries the tenant key (`organization_code` + `school_code`), `created_at`/`updated_at` (UTC `timestamptz`), `version` (optimistic lock), and `deleted_at`/`deleted_by` (soft delete). `school_code` leads composite indexes (a school is in exactly one org, so it alone scopes data); `organization_code` is carried for cross-service consistency and org-level queries. Tenant/audit columns are shown on the core tables and omitted elsewhere for brevity.

### 4.1 `tasks` — the definition

```sql
CREATE TABLE tasks (
  id                BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code              VARCHAR(40)  NOT NULL UNIQUE,            -- TSK-XXXXXXXX
  organization_code VARCHAR(40)  NOT NULL,                   -- tenant (matches staff_service)
  school_code       VARCHAR(40)  NOT NULL,                   -- tenant (code, not id — cross-service safe)
  title             VARCHAR(300) NOT NULL,
  description       TEXT         NOT NULL DEFAULT '',

  -- scope: school-wide or a specific classroom (PRD)
  scope             VARCHAR(16)  NOT NULL DEFAULT 'SCHOOL_WIDE',  -- SCHOOL_WIDE | CLASSROOM
  classroom_code    VARCHAR(40),                             -- required iff scope = CLASSROOM

  -- recurrence lives on the definition (shared cadence)
  recurring          BOOLEAN     NOT NULL DEFAULT FALSE,
  recurring_pattern  VARCHAR(16),                            -- DAILY|WEEKLY|MONTHLY
  recurring_end_date DATE,
  start_day          VARCHAR(16),                            -- weekday name or day-of-month
  due_day            VARCHAR(16),

  -- hierarchy (self-reference, depth 1 enforced in service)
  parent_task_id    BIGINT       REFERENCES tasks(id) ON DELETE SET NULL,

  -- maintained rollup columns (trigger-kept; power the board AND its sorts)
  assignment_total       INT     NOT NULL DEFAULT 0,
  assignment_in_progress INT     NOT NULL DEFAULT 0,
  assignment_completed   INT     NOT NULL DEFAULT 0,
  assignment_overdue     INT     NOT NULL DEFAULT 0,         -- job-refreshed ("as of last refresh")
  earliest_due_date      DATE,                               -- MIN(assignment.due_date); board sort key

  -- derived, indexable, and CANNOT drift: a pure function of the counters above
  aggregate_status VARCHAR(16) GENERATED ALWAYS AS (
    CASE WHEN assignment_total = 0                                    THEN 'EMPTY'
         WHEN assignment_completed = assignment_total                 THEN 'COMPLETED'
         WHEN assignment_completed = 0 AND assignment_in_progress = 0 THEN 'NOT_STARTED'
         ELSE 'IN_PROGRESS' END) STORED,

  created_by_code   VARCHAR(40)  NOT NULL,
  created_by_name   VARCHAR(160) NOT NULL,                   -- historical snapshot (creator at creation time)
  version           INT          NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at        TIMESTAMPTZ,
  deleted_by        VARCHAR(40),
  CONSTRAINT chk_task_scope CHECK ((scope = 'CLASSROOM') = (classroom_code IS NOT NULL))
);
CREATE INDEX idx_tasks_board  ON tasks (school_code, earliest_due_date)
  INCLUDE (code, title, aggregate_status, assignment_total, assignment_completed) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_status ON tasks (school_code, aggregate_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_class  ON tasks (school_code, classroom_code)  WHERE scope = 'CLASSROOM' AND deleted_at IS NULL;
CREATE INDEX idx_tasks_parent ON tasks (parent_task_id) WHERE deleted_at IS NULL;
```

Attachments and comments are **not** inline columns — they are first-class cross-linked tables (§4.3–4.4), which is what gives them independent history and lifecycle.

### 4.2 `task_assignments` — the per-person instance

```sql
CREATE TABLE task_assignments (
  id            BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code          VARCHAR(40)  NOT NULL UNIQUE,                -- TSA-XXXXXXXX
  task_id       BIGINT       NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  organization_code VARCHAR(40) NOT NULL,
  school_code   VARCHAR(40)  NOT NULL,

  assignee_code VARCHAR(40)  NOT NULL,                       -- staff code (source of truth = staff_service)
  assignee_name VARCHAR(160) NOT NULL,                       -- DISPLAY CACHE only; refreshed on sync & staff-name change

  status        VARCHAR(16)  NOT NULL DEFAULT 'TO_DO',       -- TO_DO|IN_PROGRESS|COMPLETED
  status_rank   SMALLINT     NOT NULL DEFAULT 0,             -- orderable status (sort)
  priority      VARCHAR(16)  NOT NULL DEFAULT 'MEDIUM',      -- LOW|MEDIUM|HIGH
  priority_rank SMALLINT     NOT NULL DEFAULT 1,             -- LOW=0 MEDIUM=1 HIGH=2 (sort)
  start_date    DATE         NOT NULL,
  start_time    TIME         NOT NULL DEFAULT '09:00',       -- wall-clock in school tz; serialized HH:mm at the API edge
  due_date      DATE         NOT NULL,
  due_time      TIME         NOT NULL DEFAULT '17:00',
  effort        NUMERIC(6,2) NOT NULL DEFAULT 0,
  completed_at  TIMESTAMPTZ,

  version       INT          NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at    TIMESTAMPTZ,
  deleted_by    VARCHAR(40)
);
-- one ACTIVE assignment per person per task (allows re-adding a previously removed person)
CREATE UNIQUE INDEX uq_assign_active ON task_assignments (task_id, assignee_code)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_assign_person ON task_assignments (assignee_code, school_code, due_date)
  WHERE deleted_at IS NULL;                                   -- "Jane's tasks" + default sort
CREATE INDEX idx_assign_open   ON task_assignments (school_code, due_date)
  WHERE status <> 'COMPLETED' AND deleted_at IS NULL;         -- overdue / open queries
```

> The partial unique index (`WHERE deleted_at IS NULL`) is deliberate: a plain `UNIQUE(task_id, assignee_code)` would block re-adding a staff member who was previously removed (their soft-deleted row would collide). This is a common, easily-missed correctness bug.

> **Names — cache vs. snapshot:** `assignee_name` is a *live display cache* (staff_service is the source of truth; refreshed on sync and on staff-name change) so cards render offline without a service call. By contrast, `created_by_name`, `author_name` (§4.3) and `actor_name` (§4.5) are *historical snapshots* — the name at the moment of the action — and are intentionally **not** refreshed.

### 4.3 `task_comments` — discussion (task- or assignment-scoped)

```sql
CREATE TABLE task_comments (
  id                 BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code               VARCHAR(40)  NOT NULL UNIQUE,           -- CMT-XXXXXXXX
  school_code        VARCHAR(40)  NOT NULL,

  task_id            BIGINT       REFERENCES tasks(id)            ON DELETE CASCADE,
  task_assignment_id BIGINT       REFERENCES task_assignments(id) ON DELETE CASCADE,

  author_code        VARCHAR(40)  NOT NULL,
  author_name        VARCHAR(160) NOT NULL,                   -- historical snapshot (name at comment time; NOT refreshed)
  body               TEXT         NOT NULL,                   -- 1..4000 chars, sanitized
  is_edited          BOOLEAN      NOT NULL DEFAULT FALSE,
  version            INT          NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at         TIMESTAMPTZ,
  deleted_by         VARCHAR(40),

  CONSTRAINT chk_comment_target CHECK (   -- exactly one target
    (task_id IS NOT NULL) <> (task_assignment_id IS NOT NULL))
);
CREATE INDEX idx_comment_task   ON task_comments (task_id, created_at)            WHERE deleted_at IS NULL;
CREATE INDEX idx_comment_assign ON task_comments (task_assignment_id, created_at) WHERE deleted_at IS NULL;
```

- **Task-level** thread (`task_id`) — shared announcement, visible to all assignees + admin.
- **Assignment-level** thread (`task_assignment_id`) — private between one assignee and admin/creator.
- Comment **edit history** lives in `audit_log`; `is_edited` is only a UI flag. Deletes are soft (renders "deleted"). *Whether comments are editable at all is an open product decision — see §15.8.*

### 4.4 `attachments` — versioned, with add/replace/delete history

The DB stores only the object-store **key**, never the file bytes.

```sql
CREATE TABLE attachments (
  id             BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code           VARCHAR(40)  NOT NULL UNIQUE,               -- ATT-XXXXXXXX (stable across versions)
  school_code    VARCHAR(40)  NOT NULL,

  -- polymorphic owner: a task OR assignment OR comment
  task_id            BIGINT REFERENCES tasks(id)            ON DELETE CASCADE,
  task_assignment_id BIGINT REFERENCES task_assignments(id) ON DELETE CASCADE,
  comment_id         BIGINT REFERENCES task_comments(id)    ON DELETE CASCADE,

  version        INT          NOT NULL DEFAULT 1,            -- bumps on replace; old rows kept
  is_current     BOOLEAN      NOT NULL DEFAULT TRUE,
  status         VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE',     -- ACTIVE|DELETED

  file_name      VARCHAR(300) NOT NULL,
  storage_key    TEXT         NOT NULL,                      -- S3/GCS object key (immutable per version)
  mime_type      VARCHAR(80)  NOT NULL,
  size_bytes     BIGINT       NOT NULL,
  checksum       VARCHAR(64),                                -- sha-256 (integrity / dedupe)

  uploaded_by    VARCHAR(40)  NOT NULL,
  uploaded_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_by     VARCHAR(40),
  deleted_at     TIMESTAMPTZ,

  CONSTRAINT chk_attach_owner CHECK (
    (task_id IS NOT NULL)::int + (task_assignment_id IS NOT NULL)::int
    + (comment_id IS NOT NULL)::int = 1)
);
CREATE INDEX idx_attach_task   ON attachments (task_id)            WHERE is_current AND status='ACTIVE';
CREATE INDEX idx_attach_assign ON attachments (task_assignment_id) WHERE is_current AND status='ACTIVE';
```

Lifecycle:
- **Add** → insert v1, `is_current=true`.
- **Replace** → insert a new row (same `code`, `version+1`, `is_current=true`); flip the prior row `is_current=false`. Old version + blob retained → full revision chain by `code`.
- **Delete** → `status='DELETED'` + `deleted_by/at` (soft); blob retained for restore, expired later by storage lifecycle.
- Every action recorded in `audit_log`. Access via short-lived **pre-signed URLs** generated on read.

### 4.5 `audit_log` — edit history / compliance (time-partitioned)

```sql
CREATE TABLE audit_log (
  id          BIGINT       GENERATED ALWAYS AS IDENTITY,
  school_code VARCHAR(40)  NOT NULL,
  entity_type VARCHAR(24)  NOT NULL,                          -- TASK|ASSIGNMENT|COMMENT|ATTACHMENT
  entity_code VARCHAR(40)  NOT NULL,
  action      VARCHAR(32)  NOT NULL,                          -- CREATED|UPDATED|STATUS_CHANGED|DELETED|RESTORED|ATTACH_*…
  actor_code  VARCHAR(40)  NOT NULL,
  actor_name  VARCHAR(160) NOT NULL,                          -- historical snapshot
  changes     JSONB,                                          -- {"status":{"from":"TO_DO","to":"COMPLETED"}}
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);

CREATE INDEX idx_audit_entity ON audit_log (school_code, entity_type, entity_code, created_at DESC);
-- monthly partitions created ahead (pg_partman/cron); old months detached & archived
```

Written **in the same transaction** as the mutation so history can never disagree with state.

### 4.6 `notifications` — minimal model (reliable delivery)

```sql
CREATE TABLE notifications (
  id           BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code         VARCHAR(40)  NOT NULL UNIQUE,
  school_code  VARCHAR(40)  NOT NULL,
  recipient_code VARCHAR(40) NOT NULL,                        -- staff code
  type         VARCHAR(40)  NOT NULL,                         -- TASK_ASSIGNED|COMMENT_ADDED|DUE_SOON|OVERDUE
  entity_type  VARCHAR(24)  NOT NULL,
  entity_code  VARCHAR(40)  NOT NULL,
  title        VARCHAR(200) NOT NULL,
  body         VARCHAR(500),
  is_read      BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_notif_inbox ON notifications (recipient_code, is_read, created_at DESC);
```

Producers write notifications via a **transactional outbox** (same DB transaction as the triggering change, dispatched asynchronously) so a push is never lost on a crash and never sent for a rolled-back change.

---

## 5. Derived data: counters, rollups, overdue, time zones

- **Counters** (`assignment_total`, `assignment_in_progress`, `assignment_completed`) are maintained by a **trigger on `task_assignments`, in the same transaction** — they cannot drift regardless of code path. A nightly **reconciliation job** recomputes them from source as defense-in-depth.
- **`aggregate_status` is a generated `STORED` column** derived from those counters (`EMPTY` / `NOT_STARTED` / `IN_PROGRESS` / `COMPLETED`). Because Postgres computes it, it is **indexable** (the board can sort/filter by it) yet **cannot drift** from the counts and needs no separate trigger. `progress_percent = round(100 × completed / total)`.
- **`overdue` is never a cached value.** It is time-derived, so any stored count rots as the clock advances. The board's `assignment_overdue` is a coarse, job-refreshed convenience for sorting ("as of last refresh"); the authoritative overdue flag is computed live from the partial index `idx_assign_open` on detail reads. **Rule: never cache a value derived from the current time.**
- **Time zones:** `start/due` are stored as a calendar **date** plus a wall-clock **time** as entered, interpreted in the **school's IANA time zone** (carried per school). Overdue and date sorting resolve the instant in that zone. Audit/system timestamps (`created_at`, etc.) are UTC `timestamptz`. The API returns the school `timeZone` so clients format consistently.

---

## 6. API design

### 6.1 Conventions

- **Envelope:** every response is `{ "success": bool, "message": string, "data": <payload|null> }`.
- **Errors:** standard HTTP codes — `400` validation, `401/403` auth, `404` not found, `409` version conflict, `422` business-rule violation, `429` rate-limited. `data` is null; `message` is human-readable.
- **Concurrency:** mutating requests send the entity `version` (or `If-Match` ETag); a mismatch returns `409` (lost-update protection).
- **Idempotency:** `POST` accepts an `Idempotency-Key` header; the server de-dupes for 24h so a retried create cannot duplicate a task.
- **Pagination:** keyset/cursor — responses include `nextCursor` (null at end); no `OFFSET`.
- **Caps:** max **200 assignees** per create request; comment body ≤ 4000 chars; attachment ≤ 10 MB; allowed types JPEG/PNG/WebP/PDF (validated **server-side**).
- **Identity & tenant** are derived from the JWT, never the request body. **Assignee/author names are resolved server-side from the staff service** and snapshotted where needed; create/assign requests carry staff **codes only** — never client-supplied names.

### 6.2 Endpoints

```
# Tasks (admin = definitions + rollup)
GET    /api/v1/tasks                         # board: each task ONCE + rollup; filter+sort+cursor
POST   /api/v1/tasks                         # create task + N assignments (one transaction)
GET    /api/v1/tasks/{taskCode}              # definition + status breakdown + assignments + counts
PATCH  /api/v1/tasks/{taskCode}              # edit definition (title/desc/scope/recurrence/parentTaskCode)
DELETE /api/v1/tasks/{taskCode}              # soft delete (cascade to assignments/comments)

# Assignments (per-person instances)
GET    /api/v1/tasks/{taskCode}/assignments  # per-person list for one task (admin drill-in)
POST   /api/v1/tasks/{taskCode}/assignments  # add a person
PATCH  /api/v1/assignments/{assignmentCode}  # status/priority/dates/effort
DELETE /api/v1/assignments/{assignmentCode}  # remove one person (soft)
GET    /api/v1/assignments?assigneeCode=…    # all tasks assigned to a person (admin)
GET    /api/v1/me/assignments                # "My Tasks" for the logged-in staff member

# Comments / attachments / history
GET|POST   /api/v1/tasks/{taskCode}/comments
GET|POST   /api/v1/assignments/{assignmentCode}/comments
PATCH|DELETE /api/v1/comments/{commentCode}
POST|GET   /api/v1/{entity}/{code}/attachments         # entity ∈ tasks|assignments|comments
PUT|DELETE /api/v1/attachments/{attachmentCode}        # replace (new version) | soft-delete
GET        /api/v1/{entity}/{code}/history             # audit timeline
```

### 6.3 Lean GETs

- **List** endpoints return a **thin projection** (code, title, status/priority, due, rollup counters, a small assignee-avatar preview) served from a **covering index** (index-only scan). No descriptions, nested arrays, or live aggregation.
- **Detail** is the only "fat" read — one task + bounded `assignments[]` + first page of comments + current attachments. Bounded by one task, so it stays cheap.
- No N+1: denormalized names + maintained counters mean a list row needs zero extra lookups.

### 6.4 Sorting & filtering (per persona, server-side)

Sorting is a **curated allow-list per endpoint**, each option backed by an index; arbitrary column sort is rejected (performance + safety). Every sort is keyset-paginated with `id` as a deterministic tiebreaker.

| Endpoint | Sort options |
|---|---|
| **Admin board** (`/tasks`) | `earliestDue` (default), `overdueCount`, `assignees`, `title`, `createdAt`, `progress`* |
| **Staff / person** (`/me/assignments`, `?assigneeCode`) | `dueDate` (default), `priority`, `status`, `createdAt` |

\* `progress` requires a maintained `progress_percent` column — added only if a screen actually sorts by it. Admin and staff sort **different tables** (task aggregates vs. per-person fields), so the menus differ by design. Enum fields sort on their `*_rank` columns, not text (else `HIGH < LOW < MEDIUM` alphabetically). Filters (status, priority, assignee, classroom, date range, overdue, search) apply server-side against the indexes in §4; staff filters implicitly scope to `assignee_code = me`.

### 6.5 Create payload (illustrative)

```jsonc
POST /api/v1/tasks
{
  "title": "First-aid recertification",
  "scope": "CLASSROOM",                                          // or SCHOOL_WIDE
  "classroomCode": "4-YELLOW",                                   // required iff scope = CLASSROOM
  "defaults": { "priority":"MEDIUM", "startDate":"2026-07-01", "dueDate":"2026-07-15" },
  "assignees": [
    { "code":"STF_A1" },                                         // codes ONLY — inherits defaults
    { "code":"STF_B2", "priority":"HIGH", "dueDate":"2026-07-05" }
  ]
}
```

The backend resolves each `code` to a staff name from the staff service and snapshots it onto the assignment; **the client never sends names.** The admin board response shows the task **once** with `rollup: { total, completed, inProgress, toDo, overdue, progressPercent }` and a short `assigneePreview`, not one row per person.

---

## 7. The admin & staff views

1. **Admin board** (`GET /tasks`) — one card per task with a progress bar, status distribution, overdue chip, assignee-avatar stack.
2. **Admin drill-in** (`GET /tasks/{code}`) — definition + per-assignee list (each with their own status/priority/due, inline-editable), plus the task-level comment thread.
3. **Tasks by person** (`GET /assignments?assigneeCode=`) — everything on one staff member's plate.
4. **Staff "My Tasks"** (`GET /me/assignments`) — the staff member's own assignments, rendered like the current task list; assignment detail carries the private comment thread.

---

## 8. Security & multi-tenancy

- **AuthN/Z:** JWT carries identity, role, and active `organization_code`/`school_code`. Role and tenant are taken from the token, never the request body. Assignee and author **names are resolved from the staff service**, never trusted from the client — requests carry codes only.
- **Tenant isolation:** every query is filtered by `school_code`; PostgreSQL **Row-Level Security** policies on each table enforce it at the database as a backstop, so an application bug can't leak across schools.
- **RBAC** (§9) enforced in the service layer (source of truth), mirrored client-side only to hide affordances.
- **Attachments:** type/size validated server-side; uploaded objects **malware-scanned** before becoming `ACTIVE`; access only via short-lived pre-signed URLs scoped to the requester's school.
- **Input safety:** comment/description text is sanitized; the web client escapes on render (XSS). Bodies length-capped.
- **Children's data:** task content may reference children — treat as sensitive PII. Audit all reads/writes (`audit_log`), encrypt at rest and in transit, and honor a configurable **retention policy** (§12). No task data is exposed to guardian/parent accounts.

---

## 9. Business rules & RBAC

**Rules:** one create = 1 task + N assignments in a transaction; assignees may override priority/start/due; staff edit their own assignment, admins edit any; editing the definition is limited to admin or the creator; hierarchy is depth-1 (a sub-task cannot have sub-tasks; same-school; no self-parent); deleting a parent promotes its children to top-level; comment edit/delete is author-or-admin; everything is soft-deleted.

| Action | Admin | Staff (own) | Staff (other's) | Parent |
|---|:--:|:--:|:--:|:--:|
| View admin board / any person's tasks | ✅ | ❌ | ❌ | ❌ |
| View "my tasks" | ✅ | ✅ | — | ❌ |
| Create task + assignments | ✅ | ✅ (becomes creator) | — | ❌ |
| Edit task definition | ✅ | ✅ if creator | ❌ | ❌ |
| Update an assignment (status/priority/dates) | ✅ | ✅ own | ❌ | ❌ |
| Add/remove assignees | ✅ | ✅ if creator | ❌ | ❌ |
| Comment (task or own assignment) | ✅ | ✅ | ❌ | ❌ |
| Edit/delete others' comment | ✅ | ❌ | ❌ | ❌ |
| Add/replace/delete attachment | ✅ | ✅ on own | ❌ | ❌ |

> Classroom scoping may add a visibility dimension (a classroom lead seeing only their classroom's tasks). That is an RBAC change beyond the `scope`/`classroom_code` columns — see open decision §15.9.

---

## 10. Client integration

Both clients consume the identical JSON contract; they differ only in local persistence and the offline path (mobile only).

**Flutter (mobile)** — replaces today's single `Task` model and multi-assignee fan-out:
- Domain: `Task` (definition + rollup), `TaskAssignment` (per-person), `TaskComment`, `Attachment`.
- State: `TaskBoardCubit` (admin), `MyTasksCubit` (staff), `TaskDetailCubit` (drill-in), `TaskCommentsCubit` (per-thread, paginated). The role gate decides which screen the Tasks tab mounts.
- UI: board with progress bars; drill-in with per-assignee list; staff "My Tasks" reusing today's card on `TaskAssignment`; comment thread + composer; parent picker + sub-task panel + breadcrumb; versioned attachment list.
- Data: Isar collections per entity + Dio remote datasources mapped to §6.2. `assignee_name` is cached for offline rendering and refreshed on sync.

**React (web)** — API client + React Query hooks (`useTaskBoard`, `useTaskDetail`, `usePersonAssignments`, `useComments` infinite query, optimistic `useAddComment`/`useUpdateAssignment`); components for board row, assignee status table, person view, comment thread/composer, sub-task panel, attachment list.

---

## 11. Offline & sync (mobile)

- **Assignment edits** and **comments** write optimistically to Isar with a `pending` flag and queue in an **outbox**, replayed on reconnect; last-write-wins on `updated_at`, comments are append-only (no merge conflict).
- **Create-while-offline** queues the whole `{task + assignments}` payload as one item so it replays atomically.
- **Rollup counters** are server-authoritative; cached values render offline and reconcile on refresh (server wins).

---

## 12. Operations

- **Migrations:** Flyway, forward-only, additive; the new column/tables need no backfill.
- **Backups & restore:** automated PITR backups; periodic restore drills. Soft-delete + retained attachment blobs provide an application-level undo path.
- **Retention/archival:** `audit_log` partitions detached and archived after the compliance window; soft-deleted rows and orphaned attachment blobs purged by a scheduled job after a grace period.
- **Observability — the dials that trigger the deferred upgrades:** per-tenant row counts (tasks/assignments/comments/audit), slow-query log, index-hit ratio, counter-drift alerts (reconciliation diff), outbox lag. These are the signals that say "now build partitioning / search offload / read replicas" — someone must own watching them.

---

## 13. Rollout plan

| Phase | Backend | Mobile | Web |
|---|---|---|---|
| **1 — Core** | `tasks` + `task_assignments` + counters + create/board/detail/me/person + assignment PATCH | split models; board + my-tasks + drill-in; new create payload | board + drill-in + person view |
| **2 — Hierarchy** | `parent_task_id` + validation + sub-task rollups | parent picker, sub-task panel, breadcrumb | sub-task panel, breadcrumb |
| **3 — Comments + Attachments** | `task_comments`, `attachments`, `audit_log` + CRUD | threads + composer + versioned attachments + outbox | threads + attachment UI |
| **4 — Notifications** | `notifications` + outbox dispatch (assigned / comment / due-soon / overdue) | in-app + push | in-app |

Phase 1 is the foundation; 2 and 3 parallelize after it; 4 is additive.

---

## 14. Deliberately deferred (with rationale)

These were considered and **intentionally** scoped out — not overlooked. Each has a clear trigger to revisit.

| Deferred | Why now | Revisit when |
|---|---|---|
| Database **sharding** / multiple DBs | Single Postgres serves us for years; sharding adds large complexity. | A single table approaches billions of rows, or vertical scaling nears its ceiling. |
| **Elasticsearch** search offload | Postgres trigram/FTS is sufficient at our scale. | A tenant exceeds ~1M rows with complex multi-field search. |
| **Partitioning** comments/notifications | Only `audit_log` grows unboundedly today. | Either table crosses a few million rows. |
| **Read replicas / caching tier** | Primary handles current read volume. | Read CPU sustained high; board latency regresses. |
| **Recurrence auto-regeneration** engine | Needs a scheduler + "series" model; recurrence is metadata + one resolved window today. | Product confirms tasks must auto-recreate each cycle (decision §15.2). |
| **Threaded replies / mentions / reactions** on comments | Flat threads meet the core need. | Collaboration usage demands it. |
| **Custom/flexible fields** | No requirement yet; JSONB path is reserved (never EAV). | A school needs configurable task fields. |
| **Real-time (WebSocket) updates** | Pull-to-refresh + optimistic updates suffice. | Live multi-user co-editing becomes a requirement. |

---

## 15. Open product decisions

1. **Per-person overrides at create** — confirm which fields staff may differ on (priority + dates only, or also effort?).
2. **Recurrence** — auto-regenerate a fresh task+assignments each cycle (needs a scheduler), or remain metadata + one resolved window?
3. **Comment scope default on mobile** — open the assignment (1:1) thread by default with a separate task-level "Announcements" tab, or surface both inline?
4. **Aggregate "Completed"** — only when *all* assignees finish, or a quorum?
5. **Parent delete** — promote children to top-level (current default) or cascade-delete?
6. **Audit retention window** — how long must edit history be kept for compliance?
7. **Per-assignment title/description override** — do per-person copies ever need a custom title/description? If the real need is personalized *instructions*, prefer a per-assignment `note` field over overriding the shared title — overriding it fractures the single-task identity the admin rollup depends on. Recommendation: don't add until a concrete use case exists.
8. **Comments — editable or immutable?** Schema currently allows edits (`is_edited` + full audit history). For audit integrity in a childcare setting, immutability (post a correction rather than edit) may be the stronger choice. Product to decide.
9. **Classroom-scoped task visibility** — does a classroom lead see only their classroom's tasks (an RBAC change, not just the new `scope`/`classroom_code` columns), or do all staff see school-wide tasks plus their classroom's? Affects the board's default filter and the assignee pool.

---

## Appendix A — Complete API reference

Every endpoint with full request/response. Shared shapes are defined once in A.0–A.1 and referenced by name to keep each endpoint concise.

### A.0 Shared conventions

**Base URL:** `/api/v1` · **Content-Type:** `application/json` · **All dates** ISO-8601; clock times `HH:mm` in the school time zone; `*At` timestamps UTC.

**Headers**

| Header | When | Purpose |
|---|---|---|
| `Authorization: Bearer <jwt>` | every request | identity, role, `organizationCode`, `schoolCode` (tenant is **never** in the body) |
| `Idempotency-Key: <uuid>` | every `POST` that creates | retried create cannot duplicate (de-duped 24h) |
| `If-Match: <version>` | every `PATCH`/`PUT`/`DELETE` that mutates | optimistic lock; stale version → `409` |

**Success envelope**
```jsonc
{ "success": true, "message": "Human-readable summary", "data": { /* payload */ } }
```

**Error envelope** (all non-2xx)
```jsonc
{ "success": false, "message": "Human-readable summary", "data": null,
  "error": { "code": "MACHINE_CODE", "details": null } }
```

**Validation error** (`400` / `422`)
```jsonc
{ "success": false, "message": "Validation failed", "data": null,
  "error": { "code": "VALIDATION_ERROR",
    "fields": [ { "field": "title", "message": "must not be blank" } ] } }
```

**Status codes used**

| Code | Meaning | Example `error.code` |
|---|---|---|
| `200` | OK (read / update) | — |
| `201` | Created | — |
| `400` | Malformed / validation | `VALIDATION_ERROR` |
| `401` | Missing/invalid token | `UNAUTHENTICATED` |
| `403` | Authenticated but not allowed (RBAC / wrong tenant) | `FORBIDDEN` |
| `404` | Not found (or soft-deleted / other tenant) | `TASK_NOT_FOUND`, `ASSIGNMENT_NOT_FOUND`, `COMMENT_NOT_FOUND` |
| `409` | Version conflict / idempotency replay / unique clash | `VERSION_CONFLICT`, `DUPLICATE_ASSIGNEE` |
| `422` | Business-rule violation | `SUBTASK_DEPTH_EXCEEDED`, `DUE_BEFORE_START`, `CROSS_SCHOOL_PARENT` |
| `429` | Rate limited | `RATE_LIMITED` |

**List pagination (keyset):** list responses wrap items as
```jsonc
"data": { "items": [ /* … */ ], "nextCursor": "eyJkdWUiOiIyMDI2…" /* null at end */, "limit": 20 }
```
Pass `?cursor=<nextCursor>&limit=<n>` to page; no `OFFSET`.

### A.1 Object shapes

```jsonc
// TaskBoardItem — thin row for the admin board (GET /tasks)
{ "code":"TSK-1A2B3C4D", "title":"First-aid recertification",
  "scope":"CLASSROOM", "classroomCode":"4-YELLOW",
  "aggregateStatus":"IN_PROGRESS",
  "rollup":{ "total":100, "toDo":18, "inProgress":50, "completed":32, "overdue":18, "progressPercent":32 },
  "earliestDueDate":"2026-07-05",
  "assigneePreview":[ {"code":"STF_A1","name":"Jane Doe"}, {"code":"STF_B2","name":"Raj Kumar"} ],
  "commentCount":4, "parentTaskCode":null, "version":7, "createdAt":"2026-06-20T09:00:00Z" }

// Assignment — the per-person instance
{ "code":"TSA-9001", "taskCode":"TSK-1A2B3C4D", "title":"First-aid recertification",
  "assigneeCode":"STF_A1", "assigneeName":"Jane Doe",
  "status":"COMPLETED", "priority":"MEDIUM",
  "startDate":"2026-07-01", "startTime":"09:00", "dueDate":"2026-07-15", "dueTime":"17:00",
  "effort":2.5, "isOverdue":false, "completedAt":"2026-07-09T12:00:00Z",
  "commentCount":1, "version":3, "createdAt":"2026-06-20T09:00:00Z", "updatedAt":"2026-07-09T12:00:00Z" }

// Comment
{ "code":"CMT-9F8E7D6C", "scope":"ASSIGNMENT", "taskCode":null, "assignmentCode":"TSA-9001",
  "authorCode":"STF_A1", "authorName":"Jane Doe", "body":"Booked the bus for the 10th.",
  "isEdited":false, "isDeleted":false, "version":0,
  "createdAt":"2026-06-21T14:02:00Z", "updatedAt":"2026-06-21T14:02:00Z" }

// Attachment
{ "code":"ATT-77AA22BB", "ownerType":"TASK", "ownerCode":"TSK-1A2B3C4D",
  "version":2, "isCurrent":true, "status":"ACTIVE",
  "fileName":"first-aid-guide.pdf", "mimeType":"application/pdf", "sizeBytes":284911,
  "checksum":"sha256:9b1c…", "uploadedByCode":"STF_ADMIN", "uploadedByName":"Admin User",
  "uploadedAt":"2026-06-22T10:00:00Z",
  "downloadUrl":"https://storage…/signed?exp=…" /* short-lived, present on reads only */ }

// AuditEntry
{ "action":"STATUS_CHANGED", "entityType":"ASSIGNMENT", "entityCode":"TSA-9001",
  "actorCode":"STF_A1", "actorName":"Jane Doe",
  "changes":{ "status":{"from":"IN_PROGRESS","to":"COMPLETED"} },
  "createdAt":"2026-07-09T12:00:00Z" }
```

---

### A.2 Tasks

#### GET /api/v1/tasks  — admin board (each task once + rollup)
- **Auth:** admin.
- **Query:** `status` (aggregate; repeatable), `priority`, `assigneeCode`, `classroomCode`, `scope`, `dueFrom`, `dueTo`, `overdue=true`, `q` (search title/desc), `sort` (`earliestDue|overdueCount|assignees|title|createdAt`, default `earliestDue`), `dir` (`asc|desc`), `cursor`, `limit` (≤100).
- **Request body:** none.
- **200**
```jsonc
{ "success":true, "message":"Tasks retrieved",
  "data":{ "items":[ /* TaskBoardItem … */ ], "nextCursor":null, "limit":20, "timeZone":"America/New_York" } }
```
- **Errors:** `401 UNAUTHENTICATED`, `403 FORBIDDEN` (non-admin), `400 VALIDATION_ERROR` (bad sort/cursor).

#### POST /api/v1/tasks  — create task + N assignments (one transaction)
- **Auth:** admin or staff (creator). **Headers:** `Idempotency-Key`.
- **Request**
```jsonc
{ "title":"First-aid recertification",
  "description":"Complete the annual module.",
  "scope":"CLASSROOM", "classroomCode":"4-YELLOW",          // classroomCode required iff scope=CLASSROOM
  "parentTaskCode":null,
  "recurring":false, "recurringPattern":null, "recurringEndDate":null,
  "defaults":{ "priority":"MEDIUM", "startDate":"2026-07-01", "startTime":"09:00",
               "dueDate":"2026-07-15", "dueTime":"17:00", "effort":0 },
  "assignees":[                                              // 1..200; CODES ONLY (names resolved server-side)
    { "code":"STF_A1" },
    { "code":"STF_B2", "priority":"HIGH", "dueDate":"2026-07-05" }
  ] }
```
- **201**
```jsonc
{ "success":true, "message":"2 tasks assignments created",
  "data":{ "code":"TSK-1A2B3C4D", "aggregateStatus":"NOT_STARTED",
           "rollup":{ "total":2, "toDo":2, "inProgress":0, "completed":0, "overdue":0, "progressPercent":0 },
           "assignments":[ /* Assignment … */ ], "version":0, "createdAt":"2026-06-23T11:00:00Z" } }
```
- **Errors:** `400 VALIDATION_ERROR` (blank title, empty assignees, >200, classroom mismatch), `422 DUE_BEFORE_START`, `422 CROSS_SCHOOL_PARENT` / `SUBTASK_DEPTH_EXCEEDED` (bad `parentTaskCode`), `404` (unknown assignee/parent code), `409` (idempotency replay returns the original `201` body), `403 FORBIDDEN`.

#### GET /api/v1/tasks/{taskCode}  — full detail (definition + breakdown + assignments)
- **Auth:** admin (any) / staff (only if assigned or creator).
- **200**
```jsonc
{ "success":true, "message":"Task retrieved",
  "data":{ "code":"TSK-1A2B3C4D", "title":"First-aid recertification", "description":"…",
           "scope":"CLASSROOM", "classroomCode":"4-YELLOW",
           "parentTaskCode":null, "parentTaskTitle":null,
           "recurring":false, "recurringPattern":null,
           "aggregateStatus":"IN_PROGRESS",
           "rollup":{ "total":100,"toDo":18,"inProgress":50,"completed":32,"overdue":18,"progressPercent":32 },
           "assignments":[ /* Assignment … (paginate via /assignments if large) */ ],
           "attachments":[ /* Attachment (current) … */ ],
           "commentCount":4,
           "createdByCode":"STF_ADMIN", "createdByName":"Admin User",
           "version":7, "createdAt":"2026-06-20T09:00:00Z", "timeZone":"America/New_York" } }
```
- **Errors:** `404 TASK_NOT_FOUND`, `403 FORBIDDEN`, `401`.

#### PATCH /api/v1/tasks/{taskCode}  — edit definition
- **Auth:** admin or creator. **Headers:** `If-Match: <version>`.
- **Request** (any subset)
```jsonc
{ "title":"First-aid recertification 2026", "description":"Updated module link.",
  "scope":"SCHOOL_WIDE", "classroomCode":null,
  "parentTaskCode":"TSK-PARENT01",
  "recurring":true, "recurringPattern":"MONTHLY", "recurringEndDate":"2026-12-31" }
```
- **200** → `data`: updated TaskDetail (without `assignments` array; `version` incremented).
- **Errors:** `409 VERSION_CONFLICT` (stale `If-Match`), `422 SUBTASK_DEPTH_EXCEEDED|CROSS_SCHOOL_PARENT|SELF_PARENT`, `400 VALIDATION_ERROR`, `404`, `403`.

#### DELETE /api/v1/tasks/{taskCode}  — soft delete (cascade)
- **Auth:** admin or creator. **Headers:** `If-Match`.
- **200**
```jsonc
{ "success":true, "message":"Task deleted (3 assignments, 4 comments archived)",
  "data":{ "code":"TSK-1A2B3C4D", "deletedAt":"2026-06-23T12:00:00Z" } }
```
- **Errors:** `404`, `403`, `409 VERSION_CONFLICT`.

---

### A.3 Assignments

#### GET /api/v1/tasks/{taskCode}/assignments  — per-person list (admin drill-in)
- **Auth:** admin / creator. **Query:** `status`, `sort` (`dueDate|priority|status|createdAt`), `dir`, `cursor`, `limit`.
- **200** → `data:{ items:[ Assignment… ], nextCursor, limit }`.
- **Errors:** `404 TASK_NOT_FOUND`, `403`, `401`.

#### POST /api/v1/tasks/{taskCode}/assignments  — add person(s)
- **Auth:** admin / creator. **Headers:** `Idempotency-Key`.
- **Request**
```jsonc
{ "assignees":[ { "code":"STF_C3" },
                { "code":"STF_D4", "priority":"HIGH", "dueDate":"2026-07-10" } ] }
```
- **201** → `data:{ added:[ Assignment… ], rollup:{…} }`.
- **Errors:** `409 DUPLICATE_ASSIGNEE` (already active on this task), `404` (unknown staff / task), `422 DUE_BEFORE_START`, `400`, `403`.

#### PATCH /api/v1/assignments/{assignmentCode}  — update status/priority/dates/effort
- **Auth:** the assignee (own) or admin. **Headers:** `If-Match`.
- **Request** (any subset)
```jsonc
{ "status":"COMPLETED", "priority":"LOW", "dueDate":"2026-07-20", "dueTime":"16:00", "effort":3 }
```
- **200** → `data`: updated Assignment (`version` incremented; setting `COMPLETED` stamps `completedAt`; the parent task's `rollup`/`aggregateStatus` recompute server-side).
- **Errors:** `409 VERSION_CONFLICT`, `422 DUE_BEFORE_START`, `404 ASSIGNMENT_NOT_FOUND`, `403 FORBIDDEN` (not your assignment), `400`.

#### DELETE /api/v1/assignments/{assignmentCode}  — remove one person (soft)
- **Auth:** admin / creator. **Headers:** `If-Match`.
- **200** → `{ "success":true, "message":"Assignee removed", "data":{ "code":"TSA-9002", "deletedAt":"…" } }`.
- **Errors:** `404`, `403`, `409`.

#### GET /api/v1/assignments?assigneeCode=STF_A1  — all tasks assigned to a person (admin)
- **Auth:** admin. **Query:** `assigneeCode` (required), `status`, `priority`, `classroomCode`, `dueFrom`, `dueTo`, `overdue`, `q`, `sort`, `dir`, `cursor`, `limit`.
- **200** → `data:{ items:[ Assignment… ], nextCursor, limit, timeZone }`.
- **Errors:** `400 VALIDATION_ERROR` (missing `assigneeCode`), `403`, `401`.

#### GET /api/v1/me/assignments  — "My Tasks" (logged-in staff)
- **Auth:** any staff/admin (scopes to caller). **Query:** same filter/sort set as above, **minus** `assigneeCode` (implicit = me).
- **200** → `data:{ items:[ Assignment… ], nextCursor, limit, timeZone }`.
- **Errors:** `401`.

---

### A.4 Comments

#### GET /api/v1/tasks/{taskCode}/comments  — task-level thread
- **Auth:** admin / anyone assigned to the task. **Query:** `cursor`, `limit` (default 20, oldest→newest).
- **200** → `data:{ items:[ Comment(scope=TASK)… ], nextCursor, limit }`.
- **Errors:** `404 TASK_NOT_FOUND`, `403`.

#### POST /api/v1/tasks/{taskCode}/comments  — add task-level comment
- **Auth:** admin / assigned staff. **Headers:** `Idempotency-Key`.
- **Request:** `{ "body":"Bus is booked, meet at 8am." }` (1..4000 chars).
- **201** → `data`: created Comment (`scope:"TASK"`, `authorName` resolved server-side).
- **Errors:** `400 VALIDATION_ERROR` (empty/too long), `404`, `403`.

#### GET /api/v1/assignments/{assignmentCode}/comments  — assignment-level thread
- **Auth:** the assignee or admin/creator. **Query:** `cursor`, `limit`.
- **200** → `data:{ items:[ Comment(scope=ASSIGNMENT)… ], nextCursor, limit }`.
- **Errors:** `404 ASSIGNMENT_NOT_FOUND`, `403`.

#### POST /api/v1/assignments/{assignmentCode}/comments  — add assignment-level comment
- **Auth:** the assignee or admin/creator. **Headers:** `Idempotency-Key`.
- **Request:** `{ "body":"I'm out sick on the 10th — can we move my due date?" }`.
- **201** → `data`: created Comment (`scope:"ASSIGNMENT"`).
- **Errors:** `400`, `404`, `403`.

#### PATCH /api/v1/comments/{commentCode}  — edit
- **Auth:** author or admin. **Headers:** `If-Match`. *(Gated by open decision §15.8 — if comments are made immutable, this endpoint is removed.)*
- **Request:** `{ "body":"Edited text." }`.
- **200** → `data`: updated Comment (`isEdited:true`, `version` incremented).
- **Errors:** `409 VERSION_CONFLICT`, `400`, `404 COMMENT_NOT_FOUND`, `403`.

#### DELETE /api/v1/comments/{commentCode}  — soft delete
- **Auth:** author or admin. **Headers:** `If-Match`.
- **200** → `{ "success":true, "message":"Comment deleted", "data":{ "code":"CMT-9F8E7D6C", "deletedAt":"…" } }` (thread renders a "deleted" placeholder).
- **Errors:** `404`, `403`, `409`.

---

### A.5 Attachments

The DB never stores bytes — uploads use a **pre-signed URL**. The `POST`/`PUT` returns a short-lived storage URL; the client uploads directly to object storage; the server flips the row to `ACTIVE` on the storage completion callback (no extra client call). `entity ∈ tasks | assignments | comments`.

#### POST /api/v1/{entity}/{code}/attachments  — begin upload (add)
- **Auth:** admin / owner of the entity. **Headers:** `Idempotency-Key`.
- **Request** (metadata only — validated server-side against caps: ≤10 MB; JPEG/PNG/WebP/PDF)
```jsonc
{ "fileName":"first-aid-guide.pdf", "mimeType":"application/pdf",
  "sizeBytes":284911, "checksum":"sha256:9b1c…" }
```
- **201**
```jsonc
{ "success":true, "message":"Upload authorized",
  "data":{ "attachment":{ "code":"ATT-77AA22BB", "version":1, "status":"PENDING", "isCurrent":true },
           "upload":{ "method":"PUT", "url":"https://storage…/signed?exp=…",
                      "headers":{ "Content-Type":"application/pdf" }, "expiresAt":"2026-06-23T11:10:00Z" } } }
```
- **Errors:** `422 FILE_TOO_LARGE` / `UNSUPPORTED_MEDIA_TYPE`, `400 VALIDATION_ERROR`, `404` (entity), `403`.

#### GET /api/v1/{entity}/{code}/attachments  — list current attachments
- **Auth:** admin / entity viewer. **Query:** `includeVersions=true` (optional — return the full revision chain instead of just `isCurrent`).
- **200** → `data:{ items:[ Attachment… (with short-lived downloadUrl) ] }`.
- **Errors:** `404`, `403`.

#### PUT /api/v1/attachments/{attachmentCode}  — replace (new version)
- **Auth:** admin / uploader. **Headers:** `If-Match`, `Idempotency-Key`.
- **Request:** same metadata body as `POST`.
- **201** → same shape as `POST`, with the new `version` (`prev.version + 1`); the prior version flips `isCurrent:false` once the new upload completes (old blob retained).
- **Errors:** `409 VERSION_CONFLICT`, `422`, `404 ATTACHMENT_NOT_FOUND`, `403`.

#### DELETE /api/v1/attachments/{attachmentCode}  — soft delete
- **Auth:** admin / uploader. **Headers:** `If-Match`.
- **200** → `{ "success":true, "message":"Attachment deleted", "data":{ "code":"ATT-77AA22BB", "status":"DELETED", "deletedAt":"…" } }` (blob retained for restore, expired later by storage lifecycle).
- **Errors:** `404`, `403`, `409`.

---

### A.6 History

#### GET /api/v1/{entity}/{code}/history  — audit timeline
- **Auth:** admin (full) / staff (entries on their own assignment). **Query:** `cursor`, `limit`, `action` (optional filter), `from`, `to`. `entity ∈ tasks | assignments | comments | attachments`.
- **200**
```jsonc
{ "success":true, "message":"History retrieved",
  "data":{ "items":[ /* AuditEntry … newest first */ ], "nextCursor":null, "limit":20 } }
```
- **Errors:** `404`, `403`, `401`.
