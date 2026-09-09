# NEWSLETTER MODULE — Production Readiness Audit

**Type:** AUDIT ONLY (no code modified by this audit) · **Branch:** `audit/Newslatter-fixes` (base `da643ecf`, uncommitted mandate work in tree)
**Scope:** `lib/{data,domain,presentation}/features/newsletter/**` — **58 files, 7,313 LOC** (presentation 4,473 · data 2,162 · domain 678)
**Standard:** `docs/mandate-rules.md` + MVVM golden rule `View → Cubit → UseCase → Repository → DataSource`

**Confidence:** *CONFIRMED* = traced in code · *PROBABLE* = strong signal, not fully traced · *BACKEND* = not observable from the client.

---

## 1. Verdict (superseded — see §6 Remediation)

🟡 **CONDITIONALLY READY** — no defect here can corrupt data, but two can show a parent or a teacher the wrong list.

This module is structurally the healthiest in the app: all eight mandates are met, the analyzer is clean, and it is **read-only** — three GET endpoints, zero writes. That removes by construction the entire class of duplicate-write defects that blocked attendance (no idempotency keys needed because there is nothing to make idempotent).

What remains is **correctness of what the user is shown**, and there the module has two real gaps.

**Blockers:**

1. **P1-1** — Parent newsletter search only searches the first page, and can never load the rest. A parent looking for an older newsletter is told "No Newsletters".
2. **P1-2** — A classroom-scoped staff member can fall through to an **unrestricted** newsletter query when two upstream calls fail together.

Neither is a data-integrity risk. Both are user-visible wrongness.

---

## 2. Production defects

### 🟠 P1-1 · Parent search silently cannot find anything past page 1 — *CONFIRMED*

The parent list filters **client-side over the loaded page only**:

- `StudentNewslettersCubit.loadFirstPage` takes `studentCode`, `size` (default **10**), `status`, `forceRefresh`, `background` — **no `search` parameter** ([student_newsletters_cubit.dart:19-24](lib/presentation/features/dashboard/cubit/student_newsletters_cubit.dart#L19-L24)).
- `_filterItems(state.items, query)` filters whatever happens to be loaded ([parent_newsletter_list_tab.dart](lib/presentation/features/newsletter/view/parent_newsletter_list_tab.dart)).

On its own that is merely incomplete. The compounding half is what makes it a defect:

Pagination is driven by `NotificationListener<ScrollNotification>`, which fires **only when the user actually scrolls**. When a search narrows 10 results down to 2, the list is shorter than the viewport, there is nothing to scroll, the notification never fires, and `loadMore()` is never called.

> A parent searches "sports day". It was sent two months ago and sits on page 3. The 10 loaded newsletters do not match, the filtered list is empty, the empty state reads **"No Newsletters"**, and no amount of waiting or pulling will load page 3 because the list cannot scroll. The newsletter is unreachable through search.

**Two things make this clearly a bug rather than a design choice:**

- The **staff list does it correctly** — its search goes to the API via `applyFilters(search:)` → `GET …?search=…`. The two lists disagree.
- The staff list also explicitly handles the short-content case (`if (position.maxScrollExtent <= 0) { loadNextPage(); return; }` in `_maybeLoadNextPage`). The parent list has no equivalent.

**Fix:** add `search` to `StudentNewslettersCubit.loadFirstPage` and the student datasource, matching the staff path; delete the client-side `_filterItems`. Failing that, at minimum handle `maxScrollExtent <= 0` so pagination can proceed, and change the empty state to distinguish "no newsletters" from "no matches in what is loaded".

---

### 🟠 P1-2 · Scoped staff can fall through to an unrestricted query — *CONFIRMED (client) / BACKEND (impact)*

`effectiveClassroomCodes` returns an **empty list** — meaning no `classroomCode` filter is sent at all — when a scoped user has no primary classroom, no selection, and no allowed codes ([newsletter_list_cubit.dart](lib/presentation/features/newsletter/view_model/newsletter_list_cubit.dart)):

```dart
if (!state.isStaffScoped) return selectedCodes;
final Set<String> codes = <String>{};
final String primary = (state.primaryClassroomCode ?? '').trim();
if (primary.isNotEmpty) codes.add(primary);
codes.addAll(selectedCodes);
if (codes.isEmpty && state.allowedClassroomCodes.isNotEmpty) {
  codes.add(state.allowedClassroomCodes.first);
}
return codes.toList();          // ← [] when all three are empty
```

The state that produces it is reachable:

1. `resolveNewsletterStaffScope` calls `StaffRepository.getStaffProfile()` inside a `try` whose `catch (_)` comment reads *"Fall back to cached allowed codes"* ([newsletter_staff_scope.dart](lib/core/util/newsletter_staff_scope.dart)). On a network failure it falls back.
2. If `StorageKeys.staffAllowedClassroomCodes` is also empty — first sign-in on this device — `allowed` is `[]` and `primary` stays `null`, while `isScoped` remains **true**.
3. `_maybeBootstrapStaffList` then tries to pick a default from `ClassroomState`. If that list is also empty it produces `defaultNames = []` and calls `bootstrapStaffList(selectedCodes: [])`.
4. It sets `isStaffListBootstrapped = true`, so **it never retries** for the life of the cubit.

Result: `GET /api/v1/newsletters/school/{schoolCode}` with no classroom restriction, for a user the client believes is restricted.

**Whether this actually leaks depends on the backend enforcing scope server-side, which I cannot observe from the client.** If it does, this is a cosmetic degradation. If it does not, a classroom teacher sees every classroom's newsletters. **This needs a backend answer before release.**

**Fix (client side, regardless of the backend answer):** treat "scoped but no resolvable classrooms" as an error state rather than an unrestricted query — show the failure and offer retry, and do not latch `isStaffListBootstrapped` when the bootstrap produced nothing.

---

### 🟡 P2-1 · `"Demo Test"` ships to production users — *CONFIRMED*

The staff list substitutes a placeholder when the API returns an empty author:

```dart
final String createdBy = letter.createdByName.trim().isNotEmpty
    ? letter.createdByName
    : AppStrings.newsletterUnknownAuthor;   // 'Demo Test'
```

Real users see the literal text **"Demo Test"** in the "Created by" row of a real newsletter. The parent list uses `'-'` for the identical case, so the two screens also disagree. Extracted to `AppStrings` with a `// SUSPECT:` marker during the Mandate 4 pass and deliberately left unchanged — deciding the correct copy is a product call.

### 🟡 P2-2 · No retry when the preview fails to load — *CONFIRMED*

`PreviewNewsletterScreen` renders `state.errorMessage ?? 'Unable to load newsletter.'` as static centred text. There is no retry button, no `RefreshIndicator`, and no pull-to-refresh (`grep` for retry/refresh affordances in that file returns nothing). A transient network blip means backing out and re-tapping the card. This is also the landing screen for the `NEWSLETTER_SENT` push-notification deep link, which is exactly when connectivity is least reliable.

### 🟡 P2-3 · Two parallel model stacks with four colliding class names — *CONFIRMED*

`NewsletterModel`, `NewsletterComponentModel`, `NewsletterAttachmentModel` and `NewsletterRecipientModel` each exist **twice**:

| Stack | Files | Serves |
|---|---|---|
| A | `models/newsletter_models.dart` | staff/admin list + detail |
| B | `models/newsletter_model.dart` + 3 leaf files | parent list |

They compile only because they are never imported into the same library. Their parse semantics genuinely differ — Stack A trims `layoutJson`, Stack B does not; different alias orders; different date leniency — so they cannot simply be merged without changing one endpoint's behaviour.

**Risk:** a developer told to "fix NewsletterModel" has a 50% chance of editing the one that is not on the screen they are debugging. Both stacks now have parity tests, which contains the risk but does not remove it.

### 🟡 P2-4 · Second, unguarded `url_launcher` call site — *CONFIRMED*

`newsletter_link_launcher.dart` normalises and scheme-checks newsletter body hyperlinks (audited and cleared previously). But [newsletter_attachment_grid.dart:143-145](lib/presentation/features/newsletter/widgets/newsletter_attachment_grid.dart#L143-L145) launches an attachment URL **directly**, bypassing that file entirely:

```dart
final bool opened = await launchUrl(uri, mode: LaunchMode.inAppWebView);
if (!opened) await launchUrl(uri, mode: LaunchMode.platformDefault);
```

The URL comes from `ImageUploadService` asset resolution rather than author-authored HTML, so it is lower risk — but it has none of the allowlist logic the other path was given, and any future change to that logic will not protect this site.

### 🔵 P3-1 · Dead file — *CONFIRMED*

`widgets/newsletter_html_blocks.dart` — `splitNewsletterHtmlIntoBlocks` has **zero references** in `lib` or `test`. Preserved through the structural pass because that pass was a pure move; it should be deleted.

### 🔵 P3-2 · No behavioural test coverage — *CONFIRMED*

**76 tests, all green**, but all of them are JSON parsing parity tests written during the Mandate 8 conversion. There is **zero** coverage of:

- the staff-scope resolution and bootstrap (the P1-2 path)
- pagination, filter races, cache-then-refresh
- any widget or screen

The two riskiest behaviours in the module are the two with no tests.

---

## 3. What is genuinely solid

Verified in code, not assumed:

| Area | State |
|---|---|
| **Write safety** | No POST/PUT/PATCH/DELETE exists. Three GET routes only. The duplicate-write class of defect cannot occur. |
| **Logging / PII** | Zero `print`, `debugPrint` or logger calls in all 58 files. Nothing to leak. |
| **Race safety** | `refresh()` uses a monotonic `_refreshRequestId`; `loadNextPage` binds to the current generation and is gated on `isRefreshing`/`isLoadingMore`/`hasMore`. Filter changes emit before refreshing, so the newest query wins. This is the pattern attendance was missing. |
| **Offline** | Cache-then-refresh via `CacheManager`, and the cache is deliberately written only for the unfiltered first page so a filtered result cannot poison the default list. |
| **Asset resolution** | Session cache + in-flight de-duplication + failure cooldown in `ImageUploadService`; the cubit adds idempotent guards on top. N tiles sharing a code issue one request (test-verified). |
| **Analyzer** | 0 issues across all three layers. |
| **Mandates 1–8** | All met: full GoRouter with typed args · views talk only to cubits · 2 remaining `setState`, both controller ticks · canonical `model/view/view_model/widgets` · 0 duplicate names introduced · fully tokenised with author colours correctly excluded · `MediaQuery.sizeOf` throughout · generated JSON models. |

---

## 4. Recommended order

| # | Item | Why first |
|---|---|---|
| 1 | **P1-2** backend question | Answer decides whether it is cosmetic or a leak. Ask before coding. |
| 2 | **P1-1** parent search → API | Straight port of the staff path; user-visible and reported-as-broken shaped. |
| 3 | **P2-1** `"Demo Test"` | One-line product decision. Embarrassing in a demo. |
| 4 | **P2-2** preview retry | Small, and it sits on the push-notification path. |
| 5 | **P3-2** tests for staff scope + pagination | Locks the P1 fixes. |
| 6 | **P2-4**, **P2-3**, **P3-1** | Hygiene; no user impact today. |

## 5. Release call

**Ship-able for the parent audience once P1-1 is fixed** — parents only read newsletters, and everything else on their path is sound.

**Hold the staff audience until P1-2 has a backend answer.** If the server enforces classroom scope, downgrade it to P3 and ship. If it does not, it is a P0 and must be fixed client-side first.

---

## 6. Remediation — applied

All findings except P2-3 were fixed in the same branch. **`flutter analyze lib` 109 (unchanged) · `flutter test` 1039 passing / 27 pre-existing failures unrelated to this module.**

| ID | Status | What changed |
|---|---|---|
| **P1-1** | ✅ Fixed (mitigation) | `effectiveClassroomCodes` → see below. Parent list now auto-paginates when the user *cannot* ask for the next page — filtered list empty, or too short to scroll. Empty states split three ways: error / "Searching…" / "No newsletters match your search." / "No Newsletters". Deliberately **not** a new `search` query parameter: the student endpoint accepts only `status`/`page`/`size` and I cannot verify the server would accept more. |
| **P1-2** | ✅ Fixed | `effectiveClassroomCodes` now returns `List<String>?` and yields **null**, never an empty list, for a scoped user with nothing to scope by — an empty list was what the datasource turned into an unrestricted query. `bootstrapStaffList` surfaces an error instead of querying, and **no longer latches** `isStaffListBootstrapped`, so a pull-to-refresh can recover. `refresh()` is guarded separately: it read `state.classroomCodes` directly and was a **second, independent route** to the same unrestricted query. |
| **P2-1** | ✅ Fixed | `'Demo Test'` → `'-'`, matching what the parent list already showed for the same case. Both lists now share one constant. |
| **P2-2** | ✅ Fixed | Preview failure state gained a Retry action; the one-shot load is extracted so `initState` and Retry share it. |
| **P2-4** | ✅ Fixed | Attachment opener gained an http/https allowlist. Stricter than the body-hyperlink normaliser on purpose — an attachment is a CDN file and never legitimately `mailto:`/`tel:`. Launch modes unchanged, so valid attachments open exactly as before. |
| **P3-1** | ✅ Fixed | Dead `newsletter_html_blocks.dart` deleted. |
| **P3-2** | 🟡 Partial | 9 regression tests added for the P1-2 path (`test/presentation/features/newsletter/view_model/newsletter_scope_test.dart`), including one asserting **no request is issued at all** for an unresolvable scope. Still no widget tests and no test for the parent auto-pagination. |
| **P2-3** | ❌ Not fixed | Two parallel model stacks. Needs a backend contract decision, not a refactor. |

**P1-2's backend question is now moot for safety.** The client can no longer emit an unrestricted query, so the answer only affects whether the server would *also* have caught it. Worth asking, no longer blocking.

### Residual risk

1. **Parent search costs N round-trips.** Client-side search over a paged list means a parent with 200 newsletters may trigger ~20 sequential page loads before "no match" is certain. Correct, bounded by `hasMore`, and it does not retry on failure — but server-side search remains the right fix.
2. **Nothing has been run on a device.** Every claim here is from code and unit tests.
