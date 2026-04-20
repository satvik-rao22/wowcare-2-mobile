# Role-Based Access Spec (Admin / Staff / Parent + Designations)

## 1. Purpose
Define a consistent, app-wide authorization model for users who belong to three main persona categories:

* `Admin`
* `Staff`
* `Parent`

Each persona may have one or more **designations** (e.g., different admin types, different staff types). Designations can grant similar “base access” within the same persona category, but typically cause **major permission differences on the role/persona level**, and **fine-grained differences on the designation level**.

This document describes:
1. How persona + designation should be identified at login.
2. How permissions should be computed (role-level sets + designation overrides).
3. How those permissions must be applied app-wide (routing guards, UI gating, and API enforcement).

---

## 2. Terms & Definitions
### Persona Category
The top-level category used for most UI routing and coarse permission decisions:
* `Admin`
* `Staff`
* `Parent`

### Designation
An additional classification within a persona category used for finer permission differences.
Implementation detail: In the current codebase, staff profile data includes a `staffType` that acts as a designation-like value (see `StorageKeys.staffType`).

### Permission Key
A stable string identifier for an allowed action, for example:
* `perm.students.view`
* `perm.staff.edit_profile`
* `perm.billing.read`

### Permission Set
An immutable list of permission keys granted to a role/persona/designation.

---

## 3. High-Level Rules
1. **Persona is determined at login** (based on backend role data + optional staff profile fetch).
2. **Designation is resolved at login** where possible (typically via staff profile; or via backend role mapping if available).
3. **Role-level permissions are the default** for each persona category.
4. **Designation-level permissions override/extend role-level permissions**.
5. **UI must be gated by permissions** (hide/disable inaccessible features).
6. **Backend must enforce permissions** for every protected API/operation. UI-only gating is not security.

---

## 4. Login-Time Persona & Designation Resolution

### 4.1 Existing Relevant Data (from current app)
The app already performs an auth flow that:
* Calls login and receives a `LoginResponseModel` with `roles[]` (each role has `role`, `organizationCode`, `schoolCode`).
* Calls `getLoginContext` (used for `redirectUrl`, and may return `LastLoginOrganizationCode`, `LastLoginSchoolCode`).
* For staff-like users, the app also resolves `staffCode` and may prefetch staff profile, storing:
  * `StorageKeys.staffType` (designation-like value)
  * `StorageKeys.staffCode` and `StorageKeys.staffPin` (where available)

This doc standardizes how to turn that data into:
* `personaCategory` in `{Admin, Staff, Parent}`
* `designationCode` / `designationKey` (implementation value depends on backend / profile)

### 4.2 Recommended Resolution Algorithm
Given:
* `roles[]` from `LoginResponseModel`
* optional `staffProfile.staffType` (designation)

Compute:
1. Determine persona category:
   * If a “parent/guardian role code” is present in `roles[]`, set `personaCategory = Parent`.
   * Else if a “staff designation/profile exists”, set `personaCategory = Staff`.
   * Else if an “admin role code” is present in `roles[]`, set `personaCategory = Admin`.
   * If multiple roles exist, pick the **highest-precedence** persona (recommended precedence: `Admin > Staff > Parent`).
2. Determine designation:
   * If staff profile is available, set `designationCode = staffType`.
   * Else set `designationCode` using role code mapping from backend roles (placeholder until role list is confirmed).
3. Compute final permission keys:
   * Start with role-level permission set for `personaCategory`
   * Apply designation-level set for `designationCode`
   * Apply optional denies (if you choose to support negative permissions)

### 4.3 Persona Mapping Table (fill with backend reality)
Because backend role code strings can differ, you should replace these placeholders with confirmed values.

| Persona Category | Typical Backend Role Codes (role field in `roles[]`) | Designation Source |
|---|---|---|
| `Admin` | `ORGANIZATION_ADMIN`, `SCHOOL_ADMIN` | staffType if present, else role code mapping |
| `Staff` | `STAFF`, `TEACHER`, `COUNSELOR`, etc. | `staffType` (from staff profile) |
| `Parent` | `PARENT`, `GUARDIAN`, etc. | role code mapping |

Open task: confirm exact `role` strings for Parent and Staff in the backend response and finalize this mapping.

---

## 5. Permission Model

### 5.1 Permission Key Strategy
Use a consistent naming convention:
* `perm.<module>.<action>`

Examples:
* `perm.students.view`
* `perm.students.edit`
* `perm.staff.view`
* `perm.staff.manage`
* `perm.billing.read`
* `perm.billing.update`
* `perm.communication.send`

### 5.2 Role-Level Permission Sets
Define the base permissions per persona category:
* `ADMIN_BASE_SET`
* `STAFF_BASE_SET`
* `PARENT_BASE_SET`

Design intent:
* Admin gets broad “management” abilities.
* Staff gets operational abilities (but not full management).
* Parent gets read-only / limited actions (mostly student-facing and communications).

### 5.3 Designation-Level Permission Overrides
Define per designation:
* `DESIGNATION_<code>_SET`

Precedence:
1. `finalPermissions = ADMIN_BASE_SET|STAFF_BASE_SET|PARENT_BASE_SET`
2. `finalPermissions = finalPermissions ∪ DESIGNATION_<code>_SET`

Optional denies:
* If you support `deniedPermissions`, apply:
  * `finalPermissions = (finalPermissions ∪ allowSet) - deniedSet`

---

## 6. App-Wide Application of Permissions

### 6.1 Central Authorization State (recommended)
Create a single app-wide object (provider/cubit/service) that exposes:
* `personaCategory` (`Admin|Staff|Parent`)
* `designationCode`
* `permissionKeys` (`Set<String>`)
* `isAllowed(permissionKey)` helper
* possibly: `allowedOrganizationCodes`, `allowedSchoolCodes` (optional but useful)

Where to hook:
* Initialize it after `AuthLoaded` (post login-context and optional staff profile prefetch).

### 6.2 Routing Guards (Screen Access)
Every route should be mapped to a permission requirement:
* Option A: Each screen declares `requiredPermissions` (list of permission keys).
* Option B: Central map `routeName -> requiredPermissions`.

Guard rules:
* If user lacks required permission, do:
  * redirect to a safe fallback (e.g., dashboard / access denied screen)
  * or show a “not authorized” UI.

Implementation note for current codebase:
* The app uses `onGenerateRoute: generateRoute` in `lib/main.dart` (`lib/src/app_router.dart`).
* Add permission checks in `generateRoute` OR wrap each route builder with an `AccessGuard` widget.

### 6.3 UI Gating (Visibility / Enabled State)
Use the permission layer to:
* Hide menu items in `CustomDrawer` / `CustomNavigationBar`
* Disable buttons and actions in screens
* Remove clickable edit/delete controls

Important:
* UI gating is UX. Backend must still enforce.

Current codebase reference:
* `RoleProvider` is used in `GlobalScaffold` / `CustomDrawer` to show Parent vs Admin menu items.
* Extend/replace this with `personaCategory` and/or `permissionKeys` so Staff and specific designations get correct menu logic.

### 6.4 API Enforcement (Must be Server-Side)
For every API request:
* Always include the Authorization token (already handled by `AuthInterceptor`).
* Server should validate the user’s role/permission for that endpoint.
* App should handle `403/401` and display appropriate feedback or re-login.

Design rule:
* Never rely on the app to “only call allowed endpoints”. Call gating improves UX; server decides correctness.

---

## 7. “Role-Based Login Flow” UX Requirements
When a user logs in, the app should:
1. Resolve persona + designation (Section 4).
2. Set the central access state.
3. Open the “root flow” for that persona:
   * `Admin` -> Admin landing (dashboard tabs, drawer items, etc.)
   * `Staff` -> Staff landing
   * `Parent` -> Parent landing

Integration with existing redirect flow:
* Backend can return `redirectUrl` from login-context.
* Use `redirectUrl` if present, but still ensure the target route is authorized by the permission guard.
* If `redirectUrl` points to an unauthorized feature, fallback to the persona root route.

---

## 8. Screen-to-Permission Mapping (How to Fill)
Create a table mapping screens/features to permission keys. Example format:

| Feature / Screen | Route Name / Identifier | Required Permission Keys |
|---|---|---|
| Student Profile (Parent) | `StudentScreen` (as opened by parent) | `perm.students.view` |
| Staff Attendance | `StaffAttendanceTabbedView` | `perm.attendance.staff.view` |
| Manage Staff | `StaffScreen` admin tools | `perm.staff.manage` |
| Billing (Parent) | `ParentBillingScreen` | `perm.billing.read` |
| Billing (Admin/Staff) | `BillingScreen` | `perm.billing.read`, `perm.billing.update` |

You should generate this mapping from your product requirements (feature list).

---

## 9. Storage & Caching
To support “app wide” gating without recalculating everything:
* Persist `personaCategory`, `designationCode`, and `permissionKeys` after login (optional caching).
* Invalidate and recompute on:
  * logout
  * token refresh (if permissions may change)
  * detected mismatch (e.g., different userCode)

Current codebase hints:
* `AuthCubit.loadCachedData()` already supports cached login response.
* Staff profile prefetch is currently performed during login (best-effort).

Recommendation:
* Ensure `permissionKeys` can be derived from cached data and/or be recalculated after staff profile fetch.

---

## 10. Audit & Logging (Optional but recommended)
For security and debugging:
* Log unauthorized route access attempts in development.
* Log API 403 responses with route/feature context.

---

## 11. Implementation Checklist (for “one go” work later)
1. Finalize the backend mapping:
   * exact persona role codes for Admin/Staff/Parent
   * list of designation codes (staffType or backend role mapping)
2. Create permission key naming convention and enumerate permission keys.
3. Define `ADMIN_BASE_SET`, `STAFF_BASE_SET`, `PARENT_BASE_SET`.
4. Define designation-specific permission sets/overrides.
5. Implement:
   * persona/designation resolution after login (Section 4)
   * centralized permission state provider/service
6. Add routing guards:
   * modify `generateRoute` or wrap screens with an `AccessGuard`
7. Update UI gating:
   * replace `RoleProvider` usage with persona/permission checks
8. Verify backend enforcement:
   * ensure protected APIs return 403 when unauthorized
9. Test:
   * login for each persona
   * route navigation to both allowed and forbidden screens
   * button/action gating

---

## 12. Open Questions (You should answer before finalizing permission sets)
1. What are the exact backend `roles[].role` string values for:
   * Parent/Guardian
   * Staff
   * Admin
2. What are all possible designation values (`staffType`) returned by staff profile?
3. List the app modules/features that need permissions (screens + actions).
4. For each module, what is:
   * view access?
   * edit/create/delete/approve access?

