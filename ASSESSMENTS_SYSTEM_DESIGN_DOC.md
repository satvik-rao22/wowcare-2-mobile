# WowCare Assessments 2.0 — System Design

| | |
|---|---|
| **Scope** | The Assessments module: a per-school developmental framework (Domain → Subdomain → Milestone), **age-group-scoped** parameter assignment over school-defined age groups (seedable from a framework preset — the NH Early Learning Standards ship as preset #1), per-student milestone scoring on a fixed 1–5 scale with an upsert-per-period model, and read-only roll-ups at student / classroom / school level with period-over-period radar comparison. Plus audit trail, notifications, and CWW Super-Admin impersonation. |
| **Stack** | PostgreSQL → Spring Boot (Java) REST API → two clients: React (web, primary) + Flutter (mobile). |
| **Status** | Greenfield backend. The frontend prototype (`ParameterManagement.tsx`, `StudentAssessmentProfile.tsx`, etc.) runs on mock data; no production data exists, so this can be built correctly with no migration risk. |
| **Audience** | Engineering (backend, web, mobile) + technical review. Data Model (§4) and API (§6) are the canonical contract; the PRD §17–18 marked these "reference only / to be finalised by Tech Leads" — this document finalises them. |

---

## Table of Contents

1. [Overview](#1-overview)
2. [Guiding principles](#2-guiding-principles)
3. [Core model: Parameter hierarchy + Assessment](#3-core-model-parameter-hierarchy--assessment)
4. [Data model (PostgreSQL)](#4-data-model-postgresql)
5. [Derived data: roll-ups, averages, periods, time zones](#5-derived-data-roll-ups-averages-periods-time-zones)
6. [API design](#6-api-design)
7. [The four assessment views](#7-the-four-assessment-views)
8. [Security & multi-tenancy](#8-security--multi-tenancy)
9. [Business rules & RBAC](#9-business-rules--rbac)
10. [Client integration](#10-client-integration)
11. [Offline & sync (mobile)](#11-offline--sync-mobile)
12. [Operations](#12-operations)
13. [Rollout plan](#13-rollout-plan)
14. [Deliberately deferred (with rationale)](#14-deliberately-deferred-with-rationale)
15. [Open product decisions](#15-open-product-decisions)

---

## 1. Overview

An **assessment** records how one child is progressing against one developmental **milestone** in one **period** (a calendar month), on a fixed **1–5 scale**. The framework those milestones live in is defined once per school as a three-level hierarchy:

```
Domain  (Social & Emotional)
  └─ Subdomain  (Emotional Regulation)
       └─ Milestone  (Identifies basic emotions)   ← the atomic scoring unit
```

The module serves three layers of need:

- **Staff / Teachers** score each milestone for each child in their classrooms, month by month — the only place data is *entered*.
- **School Admins** see read-only **classroom** and **school** roll-ups: domain/subdomain/milestone averages with a radar chart comparing this month to last.
- **Org Admins** see the same roll-ups across **every school** in the organisation.

Two cross-cutting concerns shape every table: **age-group assignment** (a parameter is only visible/scoreable for students whose age falls in a band it's assigned to) and **CWW Super-Admin impersonation** (cross-org support, every action stamped with `impersonator_id`). **Guardians/Parents have no access** in this release.

> **Δ from PRD — age groups replace classroom assignment.** The PRD scopes parameters to *classrooms* and assumes each classroom maps to one developmental band. Real classrooms mix ages and rarely align with the bands standards frameworks use (the NH Early Learning Standards use seven: Birth–9 m, 9–18 m, 18–24 m, 24–30 m, 30 m–3 y, 3 y, 4–5 y). This design therefore assigns parameters to **school-defined age groups** (§4.4); a student's visible milestones are resolved from their **date of birth**, not their classroom. Classrooms remain the RBAC scope (staff see their classrooms' students) and a roll-up dimension — they no longer gate which milestones a child is assessed against. A school can adopt the NH bands + framework wholesale via a **framework preset** (§4.7) or define fully custom bands and mappings.

---

## 2. Guiding principles

Built on clean architecture (`presentation → domain → data`), consistent with the existing codebase, plus the same scaling philosophy used across WowCare modules:

> **Get the irreversible-later decisions right today; defer the expensive machinery until real metrics demand it.** The PRD caps a school at ~20 domains, ~100 subdomains, ~500 milestones, ~30 students/classroom, and ~5,000 assessment records/month. That is small. We build **shard-ready, not sharded**, and compute roll-ups **live in SQL** rather than precomputing — the dataset is far too small to justify a caching tier.

**Seven rules adopted from day one** (cheap now, painful to retrofit):

| # | Rule | Rationale |
|---|---|---|
| 1 | `school_id` (tenant) on **every** table, leading every composite index; `org_id` resolvable for Org-Admin cross-school reads. | Row-level security now; shard-by-tenant later with no model change. |
| 2 | **Soft-delete / deactivate** parameters (`status`, `deleted_at`); historical assessments are **never** deleted when a parameter is deactivated. | PRD BR-DM-05 / FR-DM-16: deactivating a Domain/Subdomain/Milestone MUST preserve all historical records. |
| 3 | **No EAV.** Scores are typed columns. Age-group assignment is a **join table**, not a `text[]` column. | The frontend models the assignment set as an array; a join table makes "which milestones does age group X see" an indexed query instead of an array scan. |
| 4 | **Aggregate in SQL** (averages, statistics), never by shipping all rows to the client. | Roll-ups (classroom/school) are `AVG`/`GROUP BY` over an indexed period window — exactly what Postgres is for. |
| 5 | **Keyset (cursor) pagination** for list endpoints, not `OFFSET`. | `OFFSET` degrades on deep pages; student/assessment lists can grow. |
| 6 | **Append-only history** (`audit_log`) is its own time-partitioned table, written in the **same transaction** as the mutation. | Compliance: PRD §19 requires reconstructing what/who/when for every mutation, incl. `impersonator_id`. |
| 7 | **Upsert is a DB constraint, not application logic.** One unique key `(student_id, milestone_id, period_start)` enforces "re-assessing replaces". | PRD BR-AS-01 / FR-SA-13: re-scoring a milestone in the same period updates, never duplicates. |

---

## 3. Core model: Parameter hierarchy + Assessment

The central decision mirrors the Tasks split (definition vs per-person instance). Here it is **the framework definition** vs **the scored instance**:

- **Parameters** (`domains` → `subdomains` → `milestones`) — the *framework* (the "what"), authored once by admins. Strict three-level hierarchy; a subdomain belongs to exactly one domain, a milestone to exactly one subdomain (PRD BR-DM-01/02 — never re-parented).
- **Assessment** — the *scored instance* (the "who scored what, when"): one row per `(student, milestone, period)`. This is the only table staff write to.

```
        ┌─────────────────────────────────────────────┐
        │                  DOMAIN                       │  authored ONCE
        │  name, description, status, school_id         │  (DMN-…)
        └───────────────────────┬──────────────────────┘
                                 │ 1 : N
                                 ▼
        ┌─────────────────────────────────────────────┐
        │                 SUBDOMAIN                     │  (SBD-…)
        │  name, status, domain_id, school_id           │
        └───────────────────────┬──────────────────────┘
                                 │ 1 : N
                                 ▼
        ┌─────────────────────────────────────────────┐
        │                 MILESTONE                     │  (MST-…)
        │  name, status, subdomain_id, …                │  ← atomic scoring unit
        └───────────────────────┬──────────────────────┘
                                 │ 1 : N  (one row per student per period)
                                 ▼
        ┌─────────────────────────────────────────────┐
        │                ASSESSMENT                     │  (ASM-…)
        │  student_id, milestone_id, score(1–5),        │  UNIQUE
        │  notes, period_start, assessed_by             │  (student, milestone, period_start)
        └─────────────────────────────────────────────┘

   Age-group assignment (many-to-many) attaches to ANY parameter level:
        DOMAIN / SUBDOMAIN / MILESTONE  ──<  parameter_age_groups  >──  AGE GROUP
                                                          (school-defined band, e.g.
                                                           "Birth to Nine Months" = [0, 9) months)
```

This is what lets a milestone be scored for 30 children as 30 independent rows, lets an admin aggregate a classroom or whole school as a single `GROUP BY`, and makes "every milestone visible to age group X" a single indexed join. A student's band is resolved from `date_of_birth` at the assessment period (§4.4), so the framework follows the child — not the room they happen to sit in.

---

## 4. Data model (PostgreSQL)

> Conventions: internal PK is `BIGINT GENERATED ALWAYS AS IDENTITY` (never exposed); the API exposes only the public `code` (and/or UUID for reference entities). Every table carries `school_id` (tenant), `created_at`/`updated_at` (UTC `timestamptz`), `created_by`/`updated_by`, `version` (optimistic lock / `If-Match` ETag), and where applicable `status` + `deleted_at`/`deleted_by`. **`schools`, `classrooms`, `students`, `users`, `organisations` are reference entities owned by other modules** — shown only as FKs. Age-group resolution additionally requires **`students.date_of_birth`**, which this module reads but never writes.

### 4.1 `domains` — top-level developmental area

```sql
CREATE TABLE domains (
  id           BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code         VARCHAR(40)  NOT NULL UNIQUE,                 -- DMN-XXXXXXXX (API id)
  school_id    BIGINT       NOT NULL,
  name         VARCHAR(200) NOT NULL,
  description  VARCHAR(1000) NOT NULL DEFAULT '',
  status       VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE',       -- ACTIVE|INACTIVE (deactivate = soft delete)

  created_by   VARCHAR(40)  NOT NULL,
  updated_by   VARCHAR(40),
  version      INT          NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at   TIMESTAMPTZ,
  deleted_by   VARCHAR(40)
);
-- name unique per school, case-insensitive, among ACTIVE rows (PRD VR-DM-02)
CREATE UNIQUE INDEX uq_domain_name ON domains (school_id, lower(name))
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;
CREATE INDEX idx_domain_list ON domains (school_id, name)
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;
```

### 4.2 `subdomains` — category within a domain

```sql
CREATE TABLE subdomains (
  id          BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code        VARCHAR(40)  NOT NULL UNIQUE,                  -- SBD-XXXXXXXX
  school_id   BIGINT       NOT NULL,
  domain_id   BIGINT       NOT NULL REFERENCES domains(id),  -- never re-parented (BR-DM-01)
  name        VARCHAR(200) NOT NULL,
  status      VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE',

  created_by  VARCHAR(40)  NOT NULL,
  updated_by  VARCHAR(40),
  version     INT          NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ,
  deleted_by  VARCHAR(40)
);
-- name unique within parent domain (VR-SD-02)
CREATE UNIQUE INDEX uq_subdomain_name ON subdomains (domain_id, lower(name))
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;
CREATE INDEX idx_subdomain_by_domain ON subdomains (domain_id)
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;
```

### 4.3 `milestones` — atomic scoring unit

```sql
CREATE TABLE milestones (
  id           BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code         VARCHAR(40)  NOT NULL UNIQUE,                 -- MST-XXXXXXXX
  school_id    BIGINT       NOT NULL,
  subdomain_id BIGINT       NOT NULL REFERENCES subdomains(id),  -- never re-parented (BR-DM-02)
  domain_id    BIGINT       NOT NULL REFERENCES domains(id),     -- denormalized: roll-ups group by domain
  name         VARCHAR(200) NOT NULL,
  description  VARCHAR(1000) NOT NULL DEFAULT '',

  status       VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE',
  created_by   VARCHAR(40)  NOT NULL,
  updated_by   VARCHAR(40),
  version      INT          NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at   TIMESTAMPTZ,
  deleted_by   VARCHAR(40)
);
CREATE UNIQUE INDEX uq_milestone_name ON milestones (subdomain_id, lower(name))
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;                       -- VR-MS-02
CREATE INDEX idx_milestone_by_subdomain ON milestones (subdomain_id)
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;
CREATE INDEX idx_milestone_by_domain   ON milestones (domain_id)
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;
```

> `domain_id` on `milestones` is a deliberate denormalization. Classroom and school roll-ups group milestone scores **by domain**; carrying `domain_id` on the scored leaf avoids a two-hop join (`milestone → subdomain → domain`) on the hottest aggregate query. It's set on create and is immutable (parameters never re-parent), so it cannot drift.
>
> There is **no `age_group` column on `milestones`** — the age linkage lives in `parameter_age_groups` (§4.5). In the NH preset every milestone maps to exactly one band (that's how the source standards are written), but the join table lets a custom milestone span adjacent bands without a schema change.

### 4.4 `age_groups` — school-defined developmental bands

Each school owns its set of age bands. The set is **seeded from a framework preset** (§4.7) — the NH Early Learning Standards preset ships the seven NH bands — or the school defines fully custom bands. A band is a half-open month range `[min_age_months, max_age_months)`, so any age maps to at most one band.

```sql
CREATE TABLE age_groups (
  id             BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code           VARCHAR(40)  NOT NULL UNIQUE,              -- AGE-XXXXXXXX (API id)
  school_id      BIGINT       NOT NULL,
  name           VARCHAR(100) NOT NULL,                     -- "Birth to Nine Months"
  min_age_months SMALLINT     NOT NULL CHECK (min_age_months >= 0),
  max_age_months SMALLINT     NOT NULL,                     -- EXCLUSIVE upper bound
  sort_order     SMALLINT     NOT NULL DEFAULT 0,
  preset_code    VARCHAR(40),                               -- provenance when seeded from a preset (§4.7)

  status         VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE',
  created_by     VARCHAR(40)  NOT NULL,
  updated_by     VARCHAR(40),
  version        INT          NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at     TIMESTAMPTZ,
  deleted_by     VARCHAR(40),

  CONSTRAINT chk_age_band CHECK (max_age_months > min_age_months)
);
CREATE UNIQUE INDEX uq_age_group_name ON age_groups (school_id, lower(name))
  WHERE status = 'ACTIVE' AND deleted_at IS NULL;
-- active bands must not overlap within a school (resolution would be ambiguous); needs btree_gist
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE age_groups ADD CONSTRAINT excl_age_band_overlap EXCLUDE USING gist (
  school_id WITH =,
  int4range(min_age_months, max_age_months) WITH &&
) WHERE (status = 'ACTIVE' AND deleted_at IS NULL);
```

- **Resolution rule:** a student's age group for a period is the active band containing `age_in_months(date_of_birth, period_start)`, computed **as of `period_start`** — a child who crosses a band boundary mid-month is assessed against one deterministic band for that whole month. Gaps between bands are legal (a school may simply not assess 5-year-olds); a student whose age falls in no active band has no milestones to score and the UI says so (OQ-N1, §15).
- **Editing a band never rewrites history:** assessments carry the `age_group_id` they were scored under (§4.6); changing `min/max_age_months` affects future resolution only. Deactivation follows the same soft-delete rules as parameters.

### 4.5 `parameter_age_groups` — age-group assignment (polymorphic, many-to-many)

A parameter at **any** level is assigned to zero-or-more age groups — this **replaces the PRD's classroom assignment**. One table, exactly one owner column set (same pattern as polymorphic owners elsewhere in the codebase). In the NH preset every milestone is assigned to exactly one band; the many-to-many exists so a custom milestone can span adjacent bands, and so a whole domain/subdomain can be pinned to a band in one row.

```sql
CREATE TABLE parameter_age_groups (
  id           BIGINT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  school_id    BIGINT  NOT NULL,

  domain_id    BIGINT  REFERENCES domains(id)    ON DELETE CASCADE,
  subdomain_id BIGINT  REFERENCES subdomains(id) ON DELETE CASCADE,
  milestone_id BIGINT  REFERENCES milestones(id) ON DELETE CASCADE,

  age_group_id BIGINT  NOT NULL REFERENCES age_groups(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by   VARCHAR(40) NOT NULL,

  CONSTRAINT chk_param_owner CHECK (
    (domain_id IS NOT NULL)::int + (subdomain_id IS NOT NULL)::int
    + (milestone_id IS NOT NULL)::int = 1)
);
-- one assignment row per (parameter, age group); re-assigning is idempotent
CREATE UNIQUE INDEX uq_pag_domain    ON parameter_age_groups (domain_id, age_group_id)    WHERE domain_id    IS NOT NULL;
CREATE UNIQUE INDEX uq_pag_subdomain ON parameter_age_groups (subdomain_id, age_group_id) WHERE subdomain_id IS NOT NULL;
CREATE UNIQUE INDEX uq_pag_milestone ON parameter_age_groups (milestone_id, age_group_id) WHERE milestone_id IS NOT NULL;
-- "which milestones does age group X see" — the visibility filter for the student profile
CREATE INDEX idx_pag_by_age_group ON parameter_age_groups (age_group_id, school_id);
```

Lifecycle (adapts PRD FR-MS-18 / BR-PM-02): **un-assigning an age group deletes only the assignment row — never the assessment records.** It changes future visibility, not history. "Applies to all age groups" (adapts FR-DM-18) is a UI rendering when the assignment set equals the school's full active-band set; it is **not** a stored flag.

### 4.6 `assessments` — the scored instance

```sql
CREATE TABLE assessments (
  id             BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code           VARCHAR(40)  NOT NULL UNIQUE,               -- ASM-XXXXXXXX
  school_id      BIGINT       NOT NULL,

  student_id     BIGINT       NOT NULL,                      -- FK → students (reference module)
  classroom_id   BIGINT       NOT NULL,                      -- denormalized: staff scope + classroom roll-up
  age_group_id   BIGINT       NOT NULL REFERENCES age_groups(id),  -- band the child was in when scored (server-resolved, §4.4)
  milestone_id   BIGINT       NOT NULL REFERENCES milestones(id),

  score          SMALLINT     NOT NULL CHECK (score BETWEEN 1 AND 5),   -- VR-AS-01/02
  notes          VARCHAR(500),                               -- optional (VR-AS-03)

  period_start   DATE         NOT NULL,                      -- 1st of month (VR-AS-06). period_end is computed dynamically to avoid database redundancy.

  assessed_by    VARCHAR(40)  NOT NULL,                      -- FK → users (FR-SA-14)
  assessed_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),        -- (FR-SA-15)
  impersonator_id VARCHAR(40),                               -- set only under CWW Super-Admin impersonation

  version        INT          NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at     TIMESTAMPTZ,
  deleted_by     VARCHAR(40)
);
-- THE upsert key: re-assessing the same milestone in the same period UPDATES (BR-AS-01)
CREATE UNIQUE INDEX uq_assessment_upsert ON assessments (student_id, milestone_id, period_start)
  WHERE deleted_at IS NULL;
-- student profile: all of one student's scores in a period (one screen load)
CREATE INDEX idx_asm_student_period ON assessments (student_id, period_start)
  WHERE deleted_at IS NULL;
-- classroom roll-up: AVG over a classroom + period, grouped by milestone (age_group_id covers the optional band filter)
CREATE INDEX idx_asm_classroom_rollup ON assessments (classroom_id, period_start)
  INCLUDE (milestone_id, score, age_group_id) WHERE deleted_at IS NULL;
-- school roll-up: AVG over a school + period
CREATE INDEX idx_asm_school_rollup ON assessments (school_id, period_start)
  INCLUDE (milestone_id, score, age_group_id) WHERE deleted_at IS NULL;
```

> `age_group_id` is stamped by the **server** at save time from the resolution rule in §4.4 — the client never sends it. It freezes the band the child was actually in when scored, so later edits to a school's bands (or a switch to different bands entirely) never reinterpret history, and it gives roll-ups an indexed band filter for free.

> Why `period_start` (a `DATE`) rather than a free `period` string: it makes the upsert key precise, lets the previous-period radar comparison be a plain `period_start = current - interval '1 month'`, and indexes cleanly for range scans. `period_end` is carried for display and for the "valid calendar month" check (VR-AS-06). The pair is the canonical assessment period.

### 4.7 `framework_presets` — importable framework templates

A preset is a **read-only template of a complete framework**: an age-group set, the Domain → Subdomain → Milestone tree, and the milestone→age-group mapping. Preset #1 is the **NH Early Learning Standards** (10 domains, 73 subdomains, 477 milestones across the 7 NH bands — inside the PRD's ≤20 / ≤100 / ≤500 caps). CWW ships `SYSTEM` presets; an org can save its own custom framework as an `ORG` preset and reuse it across its schools — this is how "the school defines their age groups and their own mapping" becomes repeatable.

```sql
CREATE TABLE framework_presets (
  id             BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code           VARCHAR(40)  NOT NULL UNIQUE,              -- PRS-XXXXXXXX (e.g. PRS-NH-ELS)
  scope          VARCHAR(16)  NOT NULL,                     -- SYSTEM | ORG
  org_id         BIGINT,                                    -- non-null iff scope = ORG
  name           VARCHAR(200) NOT NULL,
  description    VARCHAR(1000) NOT NULL DEFAULT '',
  source         VARCHAR(200),                              -- attribution, e.g. "NH Early Learning Standards"
  content        JSONB        NOT NULL,                     -- full template tree (schema below)
  preset_version INT          NOT NULL DEFAULT 1,

  status         VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE',
  created_by     VARCHAR(40)  NOT NULL,
  version        INT          NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_preset_pick ON framework_presets (scope, org_id) WHERE status = 'ACTIVE';
```

`content` schema (validated server-side on create):

```jsonc
{
  "ageGroups": [
    { "key": "birth-9m", "name": "Birth to Nine Months", "minAgeMonths": 0, "maxAgeMonths": 9 }
    // …
  ],
  "domains": [{
    "name": "Social & Emotional Development",
    "description": "…",
    "subdomains": [{
      "name": "Attachment — Relationships with primary caregivers",
      "milestones": [
        { "name": "Demonstrate interest in familiar adults…", "description": "…", "ageGroups": ["birth-9m"] }
      ]
    }]
  }]
}
```

- **JSONB is acceptable here and nowhere else.** Presets are immutable, read-only templates that are only ever read whole — the no-EAV rule (§2) governs live, queryable data.
- **Applying a preset is a copy, not a link.** `POST /framework/apply-preset` transactionally inserts rows into `age_groups`, `domains`, `subdomains`, `milestones`, and `parameter_age_groups`, stamping `preset_code` provenance on the age groups. After the copy the school **owns** its framework outright — edits are local, and a later revision of the preset never mutates schools that already imported it (re-import semantics: OQ-N3, §15).
- **v1 guard:** apply is permitted only into a school with **no active parameters and no active age groups** (`422` otherwise). Merge-into-existing is deliberately deferred (§14).
- **NH mapping note:** the source spreadsheet is four-level (Domain → Strand → Construct → Milestone). The preset folds Strand + Construct into the subdomain name (e.g. "Attachment — Relationships with primary caregivers") to fit the strict three-level hierarchy (BR-DM-01/02); the resulting 73 subdomains stay under the ≤100 cap.

### 4.8 `audit_log` — compliance history (time-partitioned)

```sql
CREATE TABLE audit_log (
  id              BIGINT       GENERATED ALWAYS AS IDENTITY,
  school_id       BIGINT       NOT NULL,
  entity_type     VARCHAR(24)  NOT NULL,                     -- DOMAIN|SUBDOMAIN|MILESTONE|AGE_GROUP|PRESET|ASSESSMENT
  entity_code     VARCHAR(40)  NOT NULL,
  action          VARCHAR(40)  NOT NULL,                     -- CREATED|UPDATED|DEACTIVATED|AGE_GROUPS_UPDATED|PRESET_APPLIED|BULK_SAVED|SCORE_UPDATED
  actor_code      VARCHAR(40)  NOT NULL,
  actor_name      VARCHAR(160) NOT NULL,
  impersonator_id VARCHAR(40),                               -- non-null only for CWW Super-Admin (PRD §19 NOTE)
  changes         JSONB,                                     -- {"score":{"from":3,"to":4}} / {"added":[…],"removed":[…]}
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);

CREATE INDEX idx_audit_entity ON audit_log (school_id, entity_type, entity_code, created_at DESC);
-- monthly partitions created ahead (pg_partman/cron); old months detached & archived
```

Maps to PRD §19's event list with the assignment events renamed for the age-group model (`domain.created`, `milestone.age_groups_updated` — adapted from `milestone.classrooms_updated` — `assessment.bulk_saved`, `assessment.updated`, …) plus two new events: `age_group.created/updated/deactivated` and `preset.applied`. Written **in the same transaction** as the mutation so history can never disagree with state.

### 4.9 `notifications` — minimal model (reliable delivery)

```sql
CREATE TABLE notifications (
  id             BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code           VARCHAR(40)  NOT NULL UNIQUE,
  school_id      BIGINT       NOT NULL,
  recipient_code VARCHAR(40)  NOT NULL,                      -- user code
  type           VARCHAR(40)  NOT NULL,                      -- DOMAIN_CREATED|DOMAIN_DEACTIVATED|MILESTONE_ASSIGNED|ASSESSMENT_COMPLETE|ASSESSMENT_OVERDUE
  channel        VARCHAR(16)  NOT NULL,                      -- IN_APP|PUSH|EMAIL
  entity_type    VARCHAR(24)  NOT NULL,
  entity_code    VARCHAR(40)  NOT NULL,
  title          VARCHAR(200) NOT NULL,
  body           TEXT,
  is_read        BOOLEAN      NOT NULL DEFAULT FALSE,
  sent_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
  impersonator_id VARCHAR(40)                                -- impersonated actions do NOT notify school users (PRD §28.3)
);
CREATE INDEX idx_notif_inbox ON notifications (recipient_code, is_read, sent_at DESC);
```

Producers write via a **transactional outbox** (same DB transaction as the triggering change, dispatched asynchronously) so a push is never lost on a crash and never sent for a rolled-back change. Push is suppressed when the user is active in-app; email uses 4-hour digest batching (PRD §28.3).

---

## 5. Derived data: roll-ups, averages, periods, time zones

- **Averages are computed live in SQL, never cached.** At PRD scale (≤5,000 records/school/month) a `GROUP BY` over `idx_asm_classroom_rollup` / `idx_asm_school_rollup` is sub-second. There is no maintained `average` column to drift. **Rule: don't cache a value that's cheap to recompute and changes every time a teacher saves.**
- **The averaging formula is fixed (PRD FR-CA-08 / BR-CA-01):** `average = SUM(score) / COUNT(scored records)` for that domain/subdomain/milestone in the period. **Students with no score for an item are excluded from BOTH numerator and denominator** — they are *not* counted as zero. In SQL this falls out for free: `AVG(score)` over non-null rows. Displayed to **one decimal place**.
- **Score color bands (BR-AS-03), applied identically to student cards, classroom cards, and averages:** `≥ 4` green, `2–3` (i.e. `≥ 2 and < 4`) yellow, `< 2` red. No assessment in the period → empty/neutral badge.
- **Radar comparison (BR-CA-02):** always *selected period* vs *immediately preceding calendar month* — `period_start - interval '1 month'`. No custom comparison period. If no prior data exists, the "previous" series is omitted or shown flat (FR-SA-18).
- **Period model:** an assessment period is a calendar month — `period_start` = 1st. `period_end` is dynamically computed (last day of the month) to avoid database redundancy. **Future periods cannot be assessed** (VR-MP-01); the API rejects a future `period_start` with `400`. Stored as `DATE` in UTC ISO-8601 (PRD §22); the MonthPicker formats via browser locale.
- **Aggregate scale is fixed (BR-AS-05):** 1=Beginner, 2=Developing, 3=Intermediate, 4=Advanced, 5=Proficient — not customisable per school or domain.
- **Age group is a filter, not a grouping change:** classroom/school roll-ups still group by domain/subdomain/milestone; an optional `ageGroupId` query filter narrows the aggregate via the denormalized `assessments.age_group_id`, letting admins compare (say) their 18–24 m children against last month without mixing bands.

---

## 6. API design

### 6.1 Conventions

- **Envelope:** every response is `{ "success": bool, "message": string, "data": <payload|null> }`.
- **Errors:** standard HTTP — `400` validation / future-period, `401/403` auth & cross-school/out-of-classroom scope, `404` not found, `409` version conflict (stale `If-Match`), `422` business-rule violation, `429` rate-limited.
- **Concurrency:** mutating requests send `If-Match` (entity `version`); a mismatch returns `409` "This record was updated by another user" (PRD §24).
- **Idempotency:** Native database UPSERT naturally handles idempotency for the `bulk` endpoint, so an explicit `Idempotency-Key` mechanism is not strictly required. Retried requests will simply update with the same values.
- **Pagination:** keyset/cursor on list reads; responses include `nextCursor` (null at end).
- **Identity, role, `school_id`, and `org_id`** are derived from the JWT + `X-School-Id` header, never trusted from the body. `impersonator_id` is derived from the impersonation session, never from the client.

### 6.2 Endpoints

```
# Age groups (admin write; staff read-only)
GET    /api/v1/schools/{schoolId}/age-groups                    # active bands, ordered by sort_order
POST   /api/v1/schools/{schoolId}/age-groups
PUT    /api/v1/schools/{schoolId}/age-groups/{ageGroupCode}
DELETE /api/v1/schools/{schoolId}/age-groups/{ageGroupCode}     # deactivate (soft); history preserved

# Framework presets
GET    /api/v1/framework-presets                                # SYSTEM presets + caller's ORG presets
POST   /api/v1/schools/{schoolId}/framework/apply-preset        # {presetCode} — transactional copy (§4.7); 422 if framework non-empty
POST   /api/v1/orgs/{orgId}/framework-presets                   # save an ORG-scope preset (snapshot a school's framework or upload content)

# Parameters — Domains (admin write; staff read-only)
GET    /api/v1/schools/{schoolId}/domains                       # active hierarchy: domains+subdomains+milestones (nested)
POST   /api/v1/schools/{schoolId}/domains                       # create domain (+ age-group assignment)
PUT    /api/v1/schools/{schoolId}/domains/{domainCode}          # edit name/description/age-groups
DELETE /api/v1/schools/{schoolId}/domains/{domainCode}          # deactivate (soft); history preserved

# Subdomains & Milestones
GET    /api/v1/schools/{schoolId}/domains/{domainCode}/subdomains
POST   /api/v1/schools/{schoolId}/domains/{domainCode}/subdomains
PUT    /api/v1/schools/{schoolId}/subdomains/{subdomainCode}
DELETE /api/v1/schools/{schoolId}/subdomains/{subdomainCode}
GET    /api/v1/schools/{schoolId}/subdomains/{subdomainCode}/milestones
POST   /api/v1/schools/{schoolId}/subdomains/{subdomainCode}/milestones
PUT    /api/v1/schools/{schoolId}/milestones/{milestoneCode}
DELETE /api/v1/schools/{schoolId}/milestones/{milestoneCode}
PATCH  /api/v1/schools/{schoolId}/milestones/{milestoneCode}/age-groups   # assignment only (adapts FR-MS-14)

# Assessments — the data-entry + roll-up surface
GET    /api/v1/schools/{schoolId}/assessments?classroomId=&periodStart=&periodEnd=   # list/filter (student-list view)
POST   /api/v1/schools/{schoolId}/assessments/bulk                                   # "Save All" — bulk UPSERT, one txn
GET    /api/v1/schools/{schoolId}/assessments/student/{studentId}?periodStart=        # one student, all milestones (profile)
GET    /api/v1/schools/{schoolId}/assessments/classroom/{classroomId}?periodStart=&ageGroupId=   # classroom roll-up (avg + radar; band filter optional)
GET    /api/v1/schools/{schoolId}/assessments/school?periodStart=&ageGroupId=                    # school roll-up (stats + avg + radar; band filter optional)

# History
GET    /api/v1/schools/{schoolId}/{entity}/{code}/history       # audit timeline (entity ∈ domains|…|assessments)
```

### 6.3 Lean GETs vs the two fat reads

- **Parameter hierarchy** (`GET /domains`) returns the nested tree with per-node subdomain/milestone counts and age-group-assignment chips, served from the covering indexes in §4.1–4.5. No assessment data.
- **Student profile** (`/assessments/student/{id}`) is the data-entry read: the server resolves the student's band from `date_of_birth` + `periodStart` (§4.4), pulls that band's milestones via `idx_pag_by_age_group`, and pre-populates any existing `(student, milestone, period)` score. The response names the resolved band so the UI can show "assessing against: 18–24 months". Bounded by one student → cheap.
- **Classroom / school roll-ups** are pure aggregates computed server-side (`AVG ... GROUP BY domain_id, subdomain_id, milestone_id`) plus the previous-period series for the radar. The client never receives raw scores for a roll-up — only the rounded averages and statistics card.

### 6.4 Bulk upsert payload (the "Save All" operation)

```jsonc
POST /api/v1/schools/{schoolId}/assessments/bulk
{
  "studentId": "STU_123",
  "classroomId": "CLS_PreschoolStars",
  "periodStart": "2026-06-01",
  "periodEnd":   "2026-06-30",
  "scores": [
    { "milestoneCode": "MST_eye_contact", "score": 4, "notes": "Consistent eye contact observed" },
    { "milestoneCode": "MST_counts_to_5", "score": 3 }
    // milestones left UNSCORED are simply omitted (PRD §24: unscored not sent)
  ]
}
```

Server behaviour (PRD §23 Reliability + BR-AS-01): **transactional** — all rows upsert or none do (rollback on partial failure). Each `(studentId, milestoneCode, periodStart)` resolves against `uq_assessment_upsert`: existing → `UPDATE` (logged `assessment.updated` with old/new score); absent → `INSERT`. `assessed_by` = caller; `impersonator_id` = session impersonator if any. The server resolves the student's band from DOB + `periodStart` and stamps `age_group_id` itself — the client never sends it. A milestone not assigned to the student's resolved age group → `422` (adapts VR-AS-05); a student with no resolvable band (missing DOB / out-of-band age) → `422`; a deactivated milestone → `400` (defensive, PRD §24).

### 6.5 Common headers

| Header | Required | Purpose |
|---|---|---|
| `Authorization` | Yes | Bearer JWT (identity, role, org_id) |
| `X-School-Id` | Yes | School scope for RLS |
| `Idempotency-Key` | Optional | Not strictly required for bulk saves due to native UPSERT idempotency |
| `If-Match` | Required for PUT | ETag = `version`; `409` on stale write |

---

## 7. The four assessment views

1. **Parameter Management** (`GET /domains`) — accordion: Domain → Subdomain → Milestone with subdomain/milestone count badges, age-group chips, and Add/Edit/Deactivate/Assign-Age-Groups controls. Includes the **Age Groups** settings surface (list/create/edit bands) and the **apply-preset** entry point, shown only while the framework is empty. **Write controls hidden for Staff** (read-only hierarchy, FR-DM-03 / US-PM-07).
2. **Student Assessment** (`/assessments?classroomId=`, then `/assessments/student/{id}`) — classroom + MonthPicker filter → student card grid with domain score badges → profile with per-domain accordion showing the milestones for the student's **resolved age band** (banner: "assessing against: 18–24 months"), 1–5 `AssessmentScale` per milestone, notes, **Copy to All Milestones**, and **Save All** (bulk upsert). The only write surface.
3. **Classroom Assessment** (`/assessments/classroom/{id}`) — read-only roll-up: domain/subdomain/milestone averages table + current-vs-previous radar + assessment-guide card.
4. **School Assessment** (`/assessments/school`) — read-only school-wide roll-up: statistics card (classrooms, students, active domains, assessments in period) + averages table + radar. Org Admin may select any school in the org (FR-SC-08).

---

## 8. Security & multi-tenancy

- **Two-level tenancy:** `org_id` (organisation) → `school_id` (school). Every assessment table is `school_id`-scoped; Org Admins read across all schools in their `org_id`; School Admins and Staff are pinned to one school.
- **AuthN/Z:** JWT carries identity, role, and `org_id`; `X-School-Id` selects the active school. Role/org/tenant come from the token, never the body.
- **Tenant isolation:** every query filters by `school_id`; PostgreSQL **Row-Level Security** policies on each table enforce it at the database as a backstop. Cross-school access returns `403` (PRD §23 Security).
- **Classroom scope (BR-AS-02):** Staff may only score students in their assigned classrooms; out-of-classroom attempts (even via URL manipulation) return `403` "You do not have permission to access this student's assessments."
- **Impersonation:** CWW Super-Admin acts on behalf of any org/school; **every mutating action stamps `impersonator_id`** (logged within 100 ms, PRD §23), the impersonation banner is always visible, and impersonated actions **do not** fire notifications to school users (§28.3).
- **Children's data:** assessment scores and notes are sensitive PII. Audit all writes, encrypt at rest and in transit, honor retention (§12). No data exposed to Guardian/Parent accounts in this release.
- **Input safety:** notes/descriptions sanitized server-side; the web client escapes on render. Lengths capped (name ≤ 200, description ≤ 1000, notes ≤ 500).

---

## 9. Business rules & RBAC

**Rules:** hierarchy is strict three-level and never re-parented (BR-DM-01/02); deactivation **should cascade** at the service layer — deactivating a Domain automatically deactivates its Subdomains and Milestones to prevent orphaned active records (resolves OQ-01); deactivating any parameter preserves all historical assessments (BR-DM-05); scoring is upsert-per-`(student, milestone, period)` (BR-AS-01); the 1–5 scale is fixed (BR-AS-05); "Copy to All Milestones" overwrites every milestone score in that domain for the current student+period (BR-AS-04); un-assigning an age group preserves its existing records (adapts BR-PM-02); roll-up profiles are strictly read-only (BR-CA-03); future periods can't be assessed (VR-MP-01).

**Age-group rules (new, supersede the PRD's classroom-assignment rules):** active bands never overlap within a school (DB-enforced, §4.4); a student's band is resolved from `date_of_birth` **as of `period_start`** and stamped onto every assessment row; editing or deactivating a band changes future resolution only — stamped history stands; a preset can be applied only into an empty framework (§4.7); scoring a milestone not assigned to the student's resolved band is rejected (`422`).

| Action | Org Admin | School Admin | Staff/Teacher | CWW Super Admin | Guardian |
|---|:--:|:--:|:--:|:--:|:--:|
| View parameter hierarchy | ✅ all schools | ✅ own school | ✅ read-only, own school | ✅ impersonated | ❌ |
| Create/Edit/Deactivate Domain/Subdomain/Milestone | ✅ | ✅ own school | ❌ | ✅ (impersonated) | ❌ |
| Define/edit age groups | ✅ | ✅ own school | ❌ | ✅ (impersonated) | ❌ |
| Apply framework preset / save ORG preset | ✅ both | ✅ apply, own school | ❌ | ✅ (impersonated) | ❌ |
| Assign age groups to a parameter | ✅ | ✅ own school | ❌ | ✅ (impersonated) | ❌ |
| View student assessment list/profile | ✅ all | ✅ own school | ✅ own classrooms | ✅ (impersonated) | ❌ (future) |
| Enter/update student score (Save All, Copy to All) | ✅ | ✅ own school | ✅ own classroom students | ✅ (impersonated) | ❌ |
| View classroom roll-up | ✅ all | ✅ own school | ✅ own classroom | ✅ (impersonated) | ❌ |
| View school roll-up dashboard | ✅ all | ✅ own school | read-only own school | ✅ (impersonated) | ❌ |

---

## 10. Client integration

Both clients consume the identical JSON contract; they differ only in local persistence and the offline path (mobile only).

**React (web, primary)** — matches the existing prototype components:
- API client + React Query hooks: `useParameterHierarchy`, `useAgeGroups`, `useApplyPreset`, `useStudentAssessment` (profile + existing scores + resolved band), `useSaveAllAssessments` (optimistic bulk upsert), `useClassroomRollup`, `useSchoolRollup`.
- Components: `ParameterManagement` (accordion + `ParameterForm`/`SubdomainForm`/`MilestoneForm`/`AgeGroupAssignmentDialog` + `ConfirmDialog`), `AgeGroupSettings` (band list/editor + apply-preset), `StudentAssessmentList` (card grid + `MonthPicker`), `StudentAssessmentProfile` (`AssessmentScale`, Copy-to-All, Save-All, Recharts radar), `ClassroomAssessmentProfile`, `SchoolAssessment`.
- Libraries (PRD §25.2): Recharts (radar), shadcn/ui (Accordion/Dialog/Checkbox/Badge), Lucide icons, date-fns (MonthPicker `startOfMonth`/`endOfMonth`/`addMonths`/`subMonths`).

**Flutter (mobile)** — mirrors the existing assessments prototype already in this repo:
- Domain: `Domain`, `Subdomain`, `Milestone`, `AgeGroup`, `Assessment` + roll-up DTOs (`ClassroomRollup`, `SchoolRollup`).
- State: `ParameterCubit` (hierarchy + write), `AgeGroupCubit` (bands + apply-preset), `StudentAssessmentCubit` (profile + save-all), `ClassroomRollupCubit`, `SchoolRollupCubit`. The role gate decides whether write affordances mount (param writes gate on `role == 'admin'`, consistent with the events/tasks modules).
- Data: Isar collections per entity + Dio datasources mapped to §6.2.

---

## 11. Offline & sync (mobile)

- **Score entry** writes optimistically to Isar with a `pending` flag and queues in an **outbox**; the whole **Save-All** payload for a student+period is one outbox item so it replays atomically (matching the server's transactional bulk upsert). Last-write-wins on `assessed_at`; the `(student, milestone, period)` upsert key means a replayed save reconciles cleanly rather than duplicating.
- **Parameter edits** (admin) replay the same way; age-group-assignment changes are last-write-wins on the assignment set. Band edits and apply-preset are **online-only** (rare, admin-driven, and the overlap constraint makes offline conflict resolution not worth building).
- The client caches the school's bands but **never resolves a band itself for a save** — the server stamps `age_group_id` on replay, so an outbox item that replays after a band edit still lands on the then-current rule deterministically.
- **Roll-ups are server-authoritative** — cached averages render offline and reconcile on refresh (server wins).
- The PRD marks offline sync **out of scope for the web release** (§1.3); this section applies to the Flutter client only.

---

## 12. Operations

- **Migrations:** Flyway, forward-only, additive; greenfield tables need no backfill. The NH Early Learning Standards `SYSTEM` preset is seeded by a Flyway **data** migration generated from the source spreadsheet (477 milestones, 7 bands); preset revisions ship as new migrations bumping `preset_version`.
- **Backups & restore:** automated PITR; periodic restore drills. Soft-delete/deactivate provides an application-level undo path — note PRD FR-DM (NOTE) flags that **no "Restore Domain" UI exists yet**; reactivation today is a DB/admin-utility operation, a candidate for a future screen.
- **Retention/archival:** `audit_log` partitions detached and archived after the compliance window; soft-deleted parameter rows purged only after the retention window and only when no assessments reference them.
- **Observability — the dials that trigger deferred upgrades:** per-school row counts (assessments/month), roll-up query latency (school dashboard target < 5 s, PRD §23), bulk-save latency (< 3 s for ≤ 50 scores), audit-write lag, outbox lag, impersonation-log latency (< 100 ms). These signal when (if ever) to add a roll-up cache or partition the assessments table.

---

## 13. Rollout plan

Mirrors PRD §26.2, with the backend phased underneath it.

| Phase | Backend | Web | Mobile |
|---|---|---|---|
| **1 — Framework setup** | `age_groups` + `framework_presets` (NH ELS seed) + `domains`/`subdomains`/`milestones` + `parameter_age_groups` + CRUD/deactivate + apply-preset + hierarchy read | ParameterManagement (accordion, forms, AgeGroupAssignmentDialog) + AgeGroupSettings + apply-preset flow | parameter hierarchy (read) + admin write + age-group settings |
| **2 — First assessment cycle** | `assessments` + bulk upsert (server band resolution) + student-list/profile reads + classroom scope enforcement | StudentAssessmentList + Profile + AssessmentScale + Copy-to-All + Save-All | student profile + save-all + outbox |
| **3 — Trend analysis** | classroom + school roll-up aggregates + previous-period series + statistics card | ClassroomAssessmentProfile + SchoolAssessment + Recharts radar | roll-up views (read) |
| **4 — Ongoing** | `audit_log` + `notifications` outbox (created/deactivated/assigned/complete/overdue) + telemetry events | in-app + bell-icon panel; notification settings | in-app + push |

Phase 1 is the foundation; 2 depends on it; 3 is meaningful only after **two** consecutive assessed months (PRD §26.2 Phase 3); 4 is additive. School-Assessment dashboard is feature-flaggable per org for phased rollout (§26.3).

---

## 14. Deliberately deferred (with rationale)

These were considered and **intentionally** scoped out — not overlooked. Each has a clear trigger to revisit.

| Deferred | Why now | Revisit when |
|---|---|---|
| **Guardian/Parent read-only views** | PRD §3.2 / §26.3: explicitly out of scope for this release. | Product confirms the parent-portal sprint (OQ-04). |
| **Roll-up caching / materialized views** | Live `AVG`/`GROUP BY` at ≤5,000 rows/month is sub-second. | School-dashboard latency approaches the 5 s target sustained, or a school exceeds ~10× the scale cap. |
| **Partitioning `assessments`** | Only `audit_log` grows unboundedly. | A school crosses a few million assessment rows. |
| **Non-numeric / customisable scales** (Mastery/Not-Yet, per-school scales) | PRD §3.2 / BR-AS-05: scale is fixed 1–5. | Product requires configurable frameworks → reserved JSONB path, never EAV. |
| **Recurrence / auto-generated periods** | Periods are derived from the calendar; staff pick the month. | Product wants auto-rollover of an assessment cycle. |
| **AI recommendations / progress narratives** | PRD §3.2: explicit non-goal. | A separate AI module is greenlit. |
| **QRIS / state-reporting / PDF export** | PRD §1.3 / §3.2: separate features. | Those modules are scoped. |
| **Preset merge / re-import into a non-empty framework** | v1 applies a preset only into an empty framework (§4.7); merge semantics (rename detection, dedupe, orphan handling) are genuinely hard and not needed to launch. | A school asks to adopt a revised standards edition without abandoning its customised framework (OQ-N3). |
| **Per-student milestone overrides** (assessing a child against an out-of-band milestone) | DOB-based band resolution covers the standard case; per-child overrides complicate visibility, the 422 guard, and roll-ups. | Product asks for IEP-style individualised frameworks. |
| **Deactivation cascade** | Resolved in design: service layer will cascade deactivations to maintain data integrity (OQ-01). | N/A |
| **Web offline sync** | PRD §1.3: out of scope for web; mobile only (§11). | Low-connectivity becomes a web requirement. |

---

## 15. Open product decisions

Carried from PRD §27.6 (OQ-01…08), framed as decisions this design is ready to absorb:

1. **Deactivation cascade (OQ-01)** — **Resolved:** Deactivating a Domain MUST cascade to its Subdomains and Milestones at the service layer. This ensures data integrity and prevents orphaned active records from appearing in the UI.
2. **Milestones-per-subdomain cap (OQ-02)** — enforce a maximum? No DB limit today; the ≤500-milestones/school NFR is the only ceiling.
3. **Cross-teacher score visibility (OQ-03)** — may a teacher see scores another teacher entered for the same student? Affects the student-profile read filter, not the data model.
4. **Copy-to-All undo (OQ-07)** — should "Copy to All Milestones" be reversible in-session? Today it overwrites (BR-AS-04); an undo would need a client-side pre-image snapshot.
5. **Save-All payload size (OQ-05, Risk)** — a student with 100+ milestones may approach API timeout on bulk upsert; validate payload size + DB write time against the < 3 s / 50-score target.
6. **Mid-cycle milestone deactivation (OQ-06, Risk)** — a save payload may carry a now-inactive `milestoneId`; the API must reject it gracefully (`400`, §6.4) rather than write a score against a dead parameter.
7. **Missing or out-of-band DOB (OQ-N1)** — a student with no `date_of_birth`, or older/younger than every active band, resolves to no band: the profile shows an empty state and saves are rejected (`422`). Should admins also get a dashboard warning listing unresolvable students, so the gap is noticed before assessment week?
8. **Band edits mid-period (OQ-N2)** — editing a band mid-month changes resolution for saves made *after* the edit within the same period (already-saved rows keep their stamped band, §4.6). Acceptable, or should bands be frozen for any period that already has data?
9. **Preset re-import / versioning (OQ-N3)** — when the NH standards are revised, how does a school move to v2: full framework reset (losing custom edits) or the deferred merge path (§14)? Related: should applying a preset later show a "framework differs from preset vN" indicator?
