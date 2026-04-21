# 📘 Wowcare - Git Guidelines (Final)

## 🚨 Purpose

These guidelines ensure a clean, traceable, and reliable development and release process.

**All rules are enforced via repository settings and CI pipelines. Violations will block merges.**

---

## 🧱 Branching Strategy (Modified Gitflow)

```
main (production)
→ stage (QA/testing)
→ develop (integration)
→ feature/* and bugfix/*
```

---

## 🌳 Branch Roles

### 🟢 main (Production)

* Always reflects live production code
* Only stable, released code goes here
* 🚫 No direct commits
* 🔒 Protected branch

---

### 🟡 stage (QA / Testing)

* Used for QA validation
* Mirrors release candidate
* Only receives merges from develop
* 🚫 No direct commits

---

### 🔵 develop

* Integration branch for all ongoing work
* All features and fixes merge here first
* ✅ Must always remain buildable

---

### 🧩 feature/<feature-name>

* Used for new features
* Created from `develop`

**Examples:**

* feature/login-api
* feature/user-profile-ui

---

### 🐞 bugfix/<bug-name>

* Used for non-production bug fixes

**Example:**

* bugfix/crash-on-login

---

### 🚑 hotfix/<issue-name>

* Used for urgent production fixes

---

## 🧾 Branch Naming Rules

* Use **kebab-case** only
* No versions or environments
* Keep names short and meaningful

---

## 🔁 Workflow

### 🚀 Feature Development

1. Create branch from `develop`
2. Implement feature
3. Push branch
4. Create PR → `develop` (Squash merge)

---

### 🧪 QA Flow

1. Merge `develop` → `stage`
2. QA tests on `stage`
3. If bugs found:

   * Fix in `develop`
   * Re-merge into `stage`

---

### 📦 Release Flow

1. Merge `stage` → `main`
2. Create tag
3. Add release notes
4. Update changelog

---

### 🚑 Hotfix Flow

1. Create branch from `main`
2. Fix issue
3. PR → `main`
4. Create tag
5. Merge `main` → `develop`

---

## 🏷️ Tagging Strategy (MANDATORY)

**Format:**

```
v<major>.<minor>.<patch>
```

**Examples:**

* v1.4.5
* v1.4.6
* v2.0.0

**Rules:**

* Tags only on `main`
* Every release must have a tag
* Must include release notes

---

## 🧾 Changelog

Maintain `CHANGELOG.md`

**Format:**

```
## v1.4.5
- Added login API
- Fixed crash on checkout
```

---

## ✍️ Commit Message Rules

**Format:**

```
<type>: short description
```

**Types:**

* feat: new feature
* fix: bug fix
* chore: maintenance
* refactor: code improvement
* docs: documentation
* style: formatting only
* test: test changes

**Examples:**

* feat: add login API integration
* fix: resolve crash on checkout

---

## 🔀 Pull Request Guidelines

### 📌 Rules

* One feature or fix per PR
* Keep PRs small and focused
* No unrelated changes

---

### 🏷️ PR Title

```
<type>: short description
```

---

### 📝 PR Description

**What:**

* Description of change

**Why:**

* Reason for change

**Changes:**

* List of changes

**Testing:**

* How it was tested

---

### ✅ Approval Rules

* At least 1 approval required
* No self-merge (except hotfix)
* Resolve all comments before merge

---

## 🔐 Branch Protection Rules

### main & stage

* Require pull request
* Require approval
* Require build to pass
* No direct pushes

---

## 🧪 CI/CD Requirements

Every PR must pass:

* Flutter build
* Lint checks
* Unit tests (if available)

---

## 📦 Release Checklist

Before merging to `main`:

* QA approved
* Version updated
* Changelog updated
* No debug logs
* Correct production APIs

---

## ❄️ Code Freeze Rule

Before release:

* ❌ No new features
* ✅ Only bug fixes

---

## 🌍 Environment Rules

* stage → staging APIs
* main → production APIs

---

## ⚠️ Critical Rules

**Do NOT:**

* Commit directly to main or stage
* Use versions in branch names
* Skip tagging
* Release from random branches

**Do:**

* Use PRs for all changes
* Tag every release
* Delete branches after merge

---

## 🎯 Summary

* Structured branching
* Clean commit history
* Tagged releases
* Strict PR discipline
* CI enforced quality

Breaking this system will reintroduce instability and release risks.

---

# 🧩 Technology-Specific Guidelines

## ⚛️ React (Frontend)

### Build & CI Requirements

* npm install
* npm run build
* eslint checks
* unit tests (jest)

### Environment Setup

* .env.development
* .env.staging
* .env.production

### Rules

* API URLs must switch based on environment
* Do not hardcode endpoints
* Ensure UI works with staging APIs before release

---

## ☕ Java (Backend - Spring Boot)

### Build & CI Requirements

* mvn clean install / gradle build
* unit tests must pass
* code quality checks (checkstyle/spotbugs)

### Environment Setup

* application-dev.yml
* application-stage.yml
* application-prod.yml

### Rules

* Never break existing APIs without versioning
* Use API versioning (/v1, /v2)
* Maintain Swagger/OpenAPI documentation

---

## 📱 Flutter (Mobile App)

### Build & CI Requirements

* flutter pub get
* flutter analyze
* flutter build apk / ipa
* unit/widget tests

### Environment Setup

* Use --dart-define or env-based configs
* अलग configs for staging and production

### Rules

* Ensure app connects to staging backend before release
* No debug logs in production builds
* Validate permissions and platform configs

---

## 🔗 Cross-Team Coordination Rules

* Backend changes must be deployed to staging before frontend/mobile testing
* Breaking API changes must be communicated in advance
* QA testing is always done against staging environment
* All platforms must be aligned before production release

---

## 🏁 Final Note

This workflow is shared across React, Java, and Flutter projects.
Consistency across all repositories is mandatory for stability and scalable development.
