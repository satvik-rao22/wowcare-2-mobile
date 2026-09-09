# Messaging Module — Audit Remediation Status

Companion to [`messaging-module-audit.md`](./messaging-module-audit.md). Records what was **fixed**, what was **left compliant on inspection**, and what was **deferred with reason** — and the decisions behind each, so the module's production-readiness state is auditable.

| Field | Value |
|---|---|
| Branch | `fix/messaging-audit-remediation` (off `refactor/communication-mandates`) |
| Base state | `e52f717d` (post develop-refactor folder migration) |
| Verification | `flutter analyze` = **0 errors** across all three layers; communication test suites **pass (152)** after every batch. Analyzer warning count unchanged from baseline (10 pre-existing debug-leftover warnings in untouched cubit files). |

## Guardrail that governed every decision

Guardrail #1 — **behaviour must not change** (same render, same navigation, same payloads) — and the mandate rules' "**do not abstract for its own sake**" outrank hitting a rule's letter. Several audit findings turned out to be cases where "fixing" them would *regress* the module (change a render, diverge 40 cubits, or churn tested live-chat logic). Those were left or deferred, on purpose. That is the production-grade call, not an omission.

---

## Fixed (landed, tested)

| Batch | Commit | Mandate | What changed |
|---|---|---|---|
| 1 | `a45e1e4a` | **M7** | 12 `MediaQuery.of(context)` single-aspect reads → `paddingOf`/`viewInsetsOf`/`orientationOf` (tighter rebuild scope; behaviour identical). |
| 1 | `a45e1e4a` | **M6.3** | Deleted a dead commented-out attachment block + the orphaned `_notImplemented()` method it was the only caller of. |
| 2 | `9f203de8` | **M3.4** | Converted **all 189** relative cross-folder imports (`../..`) across data + domain + presentation to `package:wowcare/…`. Removes the latent test-breakage the standard warns about. |
| 3a | `238df6d3` | **M6.1** | Split `message_bubble_widget.dart` **2332 → 1808** + two `part` files (`message_bubble_parts` 173, `message_bubble_reaction_parts` 365). |
| 3b | `3ff2d28a` | **M6.1** | `chat_input_bar.dart` **1029 → 341** + previews 307 + input_row 391 (**all <400**); `conversation_list_screen.dart` **1036 → 575** + tiles 258 + chips 213; `admin_chat_host_screen.dart` **1299 → 871** + lists 314 + states 124. |
| 4 | `fa5f847e` | **M5.1 + M5.2** | Removed `StorageService` (and every other forbidden type) from the presentation layer. New injected domain service **`MessagingSession`** (impl `MessagingSessionImpl` over `StorageService` in data, registered in `di.dart`) replaces `StorageService` in all 5 messaging cubits — behaviour-preserving (same keys, same values). Relocated `chat_attachment_uploader.dart` from `presentation/shared/utils` → `data/features/communication/services`. Presentation now has **0** `StorageService`/`Repository`/`DataSource`/`Dio`/`SharedPreferences` types. |

**M6.1 method:** every split is a **pure move** of library-private helper widgets into Dart `part`/`part of` files — no renames, no visibility changes, shared imports, zero behaviour change. `flutter analyze` + the module's widget tests confirm each.

---

## Left compliant on inspection (no change was the right call)

- **M1 (Navigation)** — Compliant. Zero real `Navigator.push`/`MaterialPageRoute`; typed route args. (The lone textual hit is a doc comment.)
- **M2 (setState)** — Compliant. The reaction-badge `setState` is **Bucket C** (per-emoji `AnimationController` spring-in/shrink-out with `vsync`), documented in-code. `setState` is the correct tool; a `ValueNotifier` would be wrong.
- **M4 (Theming)** — the residual inline `TextStyle`s are **color- or weight-only overrides that inherit the ambient font size** (colours already tokenised), inside `Text`/`TextSpan`. No `AppTextStyles` slot inherits size, so wrapping them in `.copyWith()` would **impose a size and change the render** — forbidden by Mandate 4's own "output must be IDENTICAL." Left, by the guardrail. The two `fontFamily: 'Manrope'` lines are a documented overlay exception (bubble re-parented into an `Overlay` loses ambient theme).
- **M8 (Models)** — Compliant. No raw `Map<String,dynamic>` in domain/presentation; generated models incl. requests; hand-written mappers documented + characterization-tested.

---

## Deferred, with reason (a local fix would make production *worse*)

- **M5.3 — two `FutureBuilder`s** (`open_conversation_screen`, `message_info_dialog`) are one-shot *resolve-and-redirect* / modal displays — no cubit "already owns" that data. Converting them adds cubits for transient UI, which Mandate 6's "do not abstract for its own sake" cautions against. Judged **not a violation**.

> **M5.1 update (now FIXED, batch 4).** This was initially deferred as an app-wide convention (`storageService:` is injected into ~40 cubits app-wide). On the direction to make messaging production-grade regardless, it was done for this module — the correct per-module remediation move: messaging is now compliant and the other modules follow in their own passes. The `MessagingSession` seam is the reference pattern for those. **`StaffMessagingFilterCubit` was found to be dead code** (constructed nowhere) — flagged for deletion.
- **M3.1 / M3.2 / M3.5 — the double-nested `presentation/`, `cubit/`→`view_model/`, the `communication`↔`messaging` feature split.** App-wide structural migration; **develop-refactor is actively performing it** (it advanced twice during remediation). The mandate rules forbid doing it in one module. Defer to that migration.

---

## Remaining over-400 files (27) — the reasoned decision

After the splits, 27 non-generated files remain >400 lines. They fall into three groups, none of which should be force-split now:

1. **Single giant State classes** — `parent_messaging_thread.dart` (4239), `conversation_thread_screen.dart` (2051), `staff_messaging_thread.dart` (1867), `staff_messaging_tab.dart` (1837), `parent_direct_messaging_screen.dart` (809), `staff_or_student_selection_bulk_messaging.dart` (1082). Their bulk is **state-coupled `_build` logic**. Extracting it means passing ~10+ pieces of screen state into wrapper widgets — the exact "forward the whole state" anti-pattern the mandate's "do not abstract for its own sake" names. Splitting them safely needs a **restructuring effort gated on characterization tests**, which these largely lack. Doing it untested, on live chat, trades a real regression risk for a line count.
2. **Tested logic files** — `communication_cubit.dart` (1604), `conversation_thread_cubit.dart` (1557), `conversation_list_cubit.dart` (813), `bulk_messaging_composition_cubit.dart` (759). **Investigated and cannot be cleanly split:** the obvious technique — `extension … on <Cubit>` in a `part` file — **introduces analyzer warnings**, because `emit()` is `@protected`/`@visibleForTesting` and an extension is neither the class nor a subclass (verified with a probe: `invalid_use_of_protected_member` + `invalid_use_of_visible_for_testing_member`). Splitting them therefore requires a **collaborator-class restructure** (extract concerns into classes the cubit delegates to) — a real refactor with regression risk on tested, working state machines. Per "do not abstract for its own sake," these **stay as cohesive units** unless/until that restructure is scheduled with its risk accepted.
3. **Data layer** — `communication_repository_impl.dart` (1028), `conversation_entity_repository_impl.dart` (740), the realtime datasources. **Also can't be split via `part` extensions:** their public methods are `@override`s of the repository interface, and extension methods cannot satisfy an `implements` contract. Same conclusion — cohesive units; a responsibility-based restructure is the only path, deferred for the same reason.

**Bottom line on file size:** every file that could be split *cleanly* (moving whole helper classes, or pure non-`@override` logic) was split — 4 widget files, ~2,000 lines relocated into <400 `part` files, `chat_input_bar` fully cleared. The remaining over-400 files are blocked by real language/architecture constraints (`@override`, `@protected emit`, state coupling), not by effort. Forcing them under 400 means a restructure that trades regression risk for a metric — declined here, on purpose.

### Dead code removed (batch 5)

`StaffMessagingFilterCubit` + `StaffMessagingFilterState` (283 lines) were constructed nowhere in `lib` or `test` — deleted.

## Also found during remediation (not in the original audit)

- **Duplicate library-private class names** across screens — `_EmptyState`, `_ErrorBanner`, `_FullScreenError`, `_ConversationTileContent` appear in both `conversation_list_screen` and `admin_chat_host_screen`. Library-private, so no functional collision, but Mandate 6 says "no two classes share a name." A **shared-widget dedup** is the fix (a follow-up; extracting them to `part` files here preserved the status quo without collision).

## Recommended next phases (in order)

1. Cubit split-by-concern (group 2) — tested, lower risk.
2. Data-layer repository/datasource split (group 3).
3. State-class restructuring (group 1) — **only after** characterization tests exist for each screen, and **after** develop-refactor's folder migration lands (else the splits re-conflict).
4. Shared-widget dedup for the duplicate private names.
5. The app-wide items (M5.1, M3.1/3.2/3.5) — as part of the platform migration, not this module.
