# Messaging (Communication) Module — Engineering-Standards Audit

| Field | Value |
|---|---|
| **Module name** | Messaging (the codebase names the feature `communication`; a second `messaging` feature folder also exists — see Mandate 3) |
| **Module path(s)** | `lib/presentation/features/communication/`, `lib/data/features/communication/`, `lib/domain/features/communication/` (+ owned files outside the folder, listed below) |
| **Commit audited** | `a68af60cfa5bf8ec014921c05672982cc34f74fa` |
| **Branch** | `refactor/communication-mandates` |
| **Date** | 2026-09-09 |
| **Standard** | *WowCare 2.0 Engineering Standards: Eight Mandates* (`WowCare2-Engineering-Standards-Eight-Mandates 1.pdf`, develop @ `16b1b2b6`) + `docs/mandate-rules.md`. Where they differ, `docs/mandate-rules.md` wins (per its own statement and the prompt). |

> **Audit-only.** No code was changed. This is the **first file in `docs/audits/`**, so its headings, table columns and severity scale are the template the other module audits should copy.
>
> **Baseline caveat — read this first.** The commit audited is a **refactor branch** on which Mandates 1, 2, 4, 5, 6, 7 and 8 have already been partially applied and Mandate 3 was deliberately deferred. Verdicts therefore reflect **residual** violations after a refactor pass, not a pristine module. An un-refactored module (the state your colleagues will audit) will score materially worse — treat the "Compliant" rows here as the achievable target, not the starting point.
>
> **Severity scale** (used by every section; copy verbatim into sibling audits):
> - **Critical** — breaks the build or tests, causes data loss, or blocks other work platform-wide.
> - **High** — clear mandate breach that materially raises defect risk or maintenance cost, or spans many files / core flows.
> - **Medium** — clear, localized breach with moderate risk.
> - **Low** — minor, cosmetic, or a residual that the module already documents as an intentional exception.

---

## 1. File set audited

Method: every file below was scanned for the specific signals each mandate defines (raw navigation, `setState`, inline styles, forbidden types, `_build` methods, `MediaQuery.of`, `Map<String, dynamic>`, folder placement, cross-folder imports), and the large / representative files were read in full. Generated `*.g.dart` files were read for existence and provenance but are **excluded from the 400-line ceiling** (Mandate 6) since they are machine-output. Every finding below cites a real path and line.

**Counts:** 195 `lib` Dart files (~80,777 lines incl. generated; ~46,000 excl. generated), 24 test files, 6 owned files outside the folder.

### Presentation — `lib/presentation/features/communication/`
Sub-trees present: `cubit/`, `model/`, `bulk_messaging/{cubit,util,view,widgets}/`, `presentation/messaging/{cubit,guards,util,view,view/screens,widgets}/`, `shared/{utils,widgets}/`. Largest files: `presentation/messaging/view/parent_messaging_thread.dart` (4,239), `shared/widgets/message_bubble_widget.dart` (2,332), `presentation/messaging/view/screens/conversation_thread_screen.dart` (2,051), `presentation/messaging/view/staff_messaging_thread.dart` (1,867), `presentation/messaging/view/staff_messaging_tab.dart` (1,837), `cubit/communication_cubit.dart` (1,604), `cubit/conversation_thread_cubit.dart` (1,557), `presentation/messaging/view/screens/admin_chat_host_screen.dart` (1,299), `bulk_messaging/view/staff_or_student_selection_bulk_messaging.dart` (1,082), `presentation/messaging/view/screens/conversation_list_screen.dart` (1,036), `shared/widgets/chat_input_bar.dart` (1,029).

### Data — `lib/data/features/communication/`
`datasources/` (6), `models/` (18 hand-authored + 8 generated `.g.dart`, incl. Isar collections and the JSON DTOs), `realtime/` (3), `repositories/` (5). Largest non-generated: `repositories/communication_repository_impl.dart` (1,028), `repositories/conversation_entity_repository_impl.dart` (740), `realtime/conversation_realtime_data_source.dart` (676).

### Domain — `lib/domain/features/communication/`
`entities/` (13), `repositories/` (5), `usecases/` (63). Entities are pure Dart (verified: 0 Flutter imports, 0 `fromJson`/`toJson`).

### Owned files that live outside the module folder
`lib/app/di/communication_providers.dart`, `lib/app/di/conversation_list_cubit_factory.dart`, `lib/app/di/conversation_thread_cubit_factory.dart`, `lib/app/di/private_mode_toggle_cubit_factory.dart`, `lib/app/di/messaging_resolvers.dart`, `lib/data/services/messaging_media_downloader.dart`, plus the 7 messaging routes + `CommunicationRoutes` in `lib/core/router/app_routes.dart` and `lib/src/app_router.dart`.

### A second, separate feature tree the module reaches into
`lib/data/features/messaging/` and `lib/domain/features/messaging/` (feature-flag get/set use-cases, `get_filtered_staff_usecase`, `messaging_remote_data_source`). This is the **same product feature under a second folder name**; the communication presentation imports it (e.g. `feature_flag_cubit.dart`). Flagged under Mandate 3.

---

## 2. Summary table

| Mandate | Verdict | Violation count | Highest severity |
|---|---|---|---|
| 1 — Navigation (GoRouter everywhere) | **Compliant** | 0 | — |
| 2 — State (setState scarcely) | **Partially violated** | 4 clusters | Low |
| 3 — Folder structure | **Violated** | 5 classes of issue | High |
| 4 — Centralized theming | **Partially violated** | ~20 sites | Medium |
| 5 — Presentation talks to cubits only | **Partially violated** | 6 cubits/services + ~2 FutureBuilders | Medium |
| 6 — Reuse / pure functions / size | **Violated** | 28 oversized files + 35 `_build` methods | High |
| 7 — One responsive source | **Partially violated** | 12 sites | Low |
| 8 — Models, not raw maps | **Compliant** | 0 | — |

---

## 3. Overall risk assessment

The module's *runtime* discipline is in good shape: navigation is fully on GoRouter with typed route arguments, domain entities are pure, all API payloads have generated models (requests included), and there is not a single raw `Map<String, dynamic>` left in the domain or presentation layers — Mandates 1 and 8 are clean. The real risk is **structural and sits in two mandates: 3 (folder structure) and 6 (file size / `_build` methods)**, which the PDF scorecard already named this module the worst offender for. Twenty-eight non-generated files exceed the 400-line ceiling — one thread screen is 4,239 lines — and the presentation layer still carries `cubit/`, `util/` and a `presentation/` folder nested *inside* `presentation/`, plus 82 relative cross-folder imports that the standard explicitly warns will compile in the app but break under test file-URIs. Mandates 4, 5 and 7 are close to the line with small, mostly-documented residuals (a handful of inline `TextStyle`s, cubits holding `StorageService`, `MediaQuery.of` used for non-size reads) that are low-to-medium risk and cheap to close.

---

## 4. Findings by mandate

### Mandate 1 — GoRouter everywhere, MaterialPageRoute nowhere — **Compliant**

**Rule** (`docs/mandate-rules.md` §"MANDATE 1"; PDF §1.2): *"No `Navigator.push`, `Navigator.of(context).push`, or `MaterialPageRoute` anywhere under `lib/presentation`."* … *"Route arguments are **typed** … No `Object?`, no `dynamic`, no untyped casts at the receiving end."*

- Zero real `Navigator.push` / `Navigator.of(context).push` / `MaterialPageRoute` calls under the module's presentation tree. The only textual match, `presentation/features/communication/model/communication_route_args.dart:14`, is a **doc comment** describing the pattern that was replaced, not a call.
- 23 `context.push/go/pop` sites; route argument classes are typed in `model/communication_route_args.dart` (`ConversationThreadArgs`, `SeededThreadArgs`, `MediaViewerArgs`, `MessageCompositionArgs`, `RecipientSelectionArgs`, `AttachmentGalleryArgs`, `MessagingFilterArgs`) and read via `state.extra! as <Type>` in the router builders.

No violations. (Modals via `showDialog`/`showModalBottomSheet` are exempt per the rule and were not counted.)

---

### Mandate 2 — setState scarcely, ValueNotifier for UI micro-state — **Partially violated**

**Rule** (§"MANDATE 2"; PDF §2.2): business/screen state → Cubit; UI micro-state → `ValueNotifier` + `ValueListenableBuilder`; controller ticks → `setState` is fine. *"Bucket A is 'no exceptions' — if it survives a parent rebuild, is read by more than one widget, or comes from an API, it is Cubit state."*

Only **10 `setState` calls** remain in the whole module — most of the mandate work is done. The residuals:

**2.1 — Reaction-count display held in `setState` (Bucket B → ValueNotifier)** · Medium-Low
- `shared/widgets/message_bubble_widget.dart:2172, 2183, 2205, 2211`
  ```dart
  setState(() => _displayed[emoji] = widget.counts[emoji]!);
  ...
  if (mounted) setState(() => _displayed.remove(emoji));
  ```
- **Why:** `_displayed` is per-widget UI micro-state driving an animated reaction chip. Per the rule this is Bucket B and should be a `ValueNotifier` + `ValueListenableBuilder` with a `child:` passed through, which is the actual performance win the mandate exists for.
- **Severity: Low** — self-contained to one bubble, no cross-widget or API coupling; purely a rebuild-scope optimization.
- **Fix:** hold `_displayed` as a `ValueNotifier<Map<String,int>>` final field, dispose it, and wrap only the chip row in `ValueListenableBuilder`.

**2.2 — Context-reload epoch counter (Bucket A-adjacent)** · Low
- `presentation/messaging/view/messaging_screen.dart:61, 86` — `setState(() => _contextReloadEpoch++);`
- **Why:** an integer bumped to force a subtree rebuild when the active school/context changes. It survives rebuilds and drives a data reload, which leans Bucket A; a `ValueNotifier` or a cubit-published epoch would scope the rebuild.
- **Severity: Low** — behaviourally correct; only rebuild-scope is at issue.
- **Fix:** publish the epoch from the owning cubit (or a `ValueNotifier`) and select on it.

**2.3 — Media-viewer load/error state in `setState` (Bucket A)** · Low
- `presentation/messaging/widgets/show_full_screen_media_view.dart:563, 581` — download progress and `_initError`.
- **Why:** async load state is Bucket A by the letter of the rule ("comes from an API/IO"). It is, however, fully local to a throwaway full-screen viewer.
- **Severity: Low.**
- **Fix:** optional — a small view-model cubit for the viewer, or leave as a documented Bucket-C-ish controller tick.

*(The remaining single `setState` in `conversation_thread_screen.dart` and `parent_messaging_thread.dart` are controller-lifecycle ticks — Bucket C, compliant.)*

---

### Mandate 3 — Folder structure, followed strictly — **Violated**

**Rule** (§"MANDATE 3"; PDF §3.1, §3.4): canonical presentation layout is `model/ view/ view_model/ widgets/`; *"`cubit/` → `view_model/`"*; *"A presentation `util/` or `utils/` folder should not exist"*; *"All cross-folder imports use `package:wowcare/...` … Relative imports only within the same folder … an import with one too many `..` compiles in the app and breaks the moment a test reaches it by file URI."* The PDF scorecard (§0.1) names this module the single worst offender: *"communication/presentation/ nested inside presentation/."*

**3.1 — `presentation/` nested inside `presentation/`** · High
- Path: `lib/presentation/features/communication/presentation/messaging/…` (holds `view/`, `widgets/`, `cubit/`, `guards/`, `util/`).
- **Why:** the canonical layout has no `presentation/` segment under a feature; this double-nesting is the exact structure the PDF calls out. It also produces the deep `../../../../` relative imports in 3.4.
- **Severity: High** — it is the structural root the other Mandate-3 issues hang off, and it makes every path in the feature longer and import math error-prone.
- **Fix:** collapse `communication/presentation/messaging/*` up into `communication/{view,widgets,view_model}/`. App-wide-ish; do as one isolated move with import rewrites.

**3.2 — `cubit/` instead of `view_model/`** · Medium
- `communication/cubit/`, `communication/bulk_messaging/cubit/`, `communication/presentation/messaging/cubit/`.
- **Why:** the rule renames `cubit/` → `view_model/`. **Ambiguity flagged:** the rule itself says *"17 of 19 features use `cubit/`, so this is app-wide — confirm before doing it in one module alone."* This is therefore a real violation but **not** one to fix in this module in isolation.
- **Severity: Medium** — naming only, no behaviour.
- **Fix:** part of the app-wide `cubit/`→`view_model/` rename; do not do it here alone.

**3.3 — Presentation `util/` folders exist** · Medium
- `communication/bulk_messaging/util/` (`messaging_shortcut.dart`), `communication/presentation/messaging/util/` (`message_entity_mapper.dart`), `communication/shared/utils/` (11 files: `attachment_open_helper.dart`, `chat_attachment_uploader.dart`, `message_content_processor.dart`, `messaging_time_formatter.dart`, …).
- **Why:** *"A presentation `util/` or `utils/` folder should not exist. Pure business rules go to `domain/…/usecases/`; mappers go to `data/…/mappers/`; presentation helpers go to `widgets/` or `core/extensions/`."* `message_entity_mapper.dart` is a mapper living in presentation; `chat_attachment_uploader.dart` is a service (see Mandate 5).
- **Severity: Medium** — misplacement, and it hides a layering breach (a mapper and a service in presentation).
- **Fix:** move mappers to `data/features/communication/mappers/`, pure formatters to `core/extensions/`, and the uploader service behind an injected interface (ties to Mandate 5).

**3.4 — 82 relative cross-folder imports** · High
- 82 `import '../…'` statements reach across folders: 30 into `domain/features/communication`, 19 into `shared/common`, 7 into `core/util`, 2 into `shared/utils`, 2 into `domain/features/messaging`. Examples:
  - `cubit/communication_cubit.dart:16-19` → `../../../../domain/features/communication/entities/…`
  - `cubit/feature_flag_cubit.dart:3-4` → `../../../../domain/features/messaging/usecases/…`
- **Why:** the rule requires `package:wowcare/...` for all cross-folder imports and explicitly warns that a relative import with one too many `..` "compiles in the app and breaks the moment a test reaches it by file URI." With 82 of them at depth `../../../../`, this is a latent test-breakage surface, not a style nit.
- **Severity: High** — correctness risk under test, at scale.
- **Fix:** convert every cross-folder relative import to `package:wowcare/...`. Mechanical, but must be one isolated pass with `flutter analyze` + the test suite green before and after.

**3.5 — The feature is split across two folder names (`communication` + `messaging`)** · Medium
- `lib/data/features/messaging/` and `lib/domain/features/messaging/` hold feature-flag and filtered-staff logic that the `communication` presentation consumes.
- **Why:** the standard assumes one folder per feature; the same product feature living under two names (`communication` and `messaging`) is exactly the "4 competing layouts / module code outside its folder" problem the scorecard describes, and it is why 3.4 has cross-`messaging` imports.
- **Severity: Medium** — no runtime bug, but it defeats the "one feature, one folder" premise the whole structure rests on.
- **Fix:** decide one canonical feature name and fold the `messaging` tree into it (or document why feature-flags are a separate cross-cutting feature). **Open question — see §6.**

---

### Mandate 4 — Centralized theming, constants, strings, colors, fonts, sizes — **Partially violated**

**Rule** (§"MANDATE 4"; PDF §4.3): *"No inline `TextStyle(`. Use `Theme.of(context).textTheme.<slot>` or a named `AppTextStyles` entry; local variation uses `.copyWith()` on a named style, never a fresh `TextStyle`."* … *"No `fontFamily: 'Manrope'`."* … *"No `Color(0x...)` and no `Colors.<name>` outside `core/theme/app_colors.dart`."*

The bulk of the module already routes through `AppColors` / `AppTextStyles` / `AppStrings` / `AppSizes`. Residuals:

**4.1 — Fresh `TextStyle(` constructions** · Medium
- Real (non-comment) sites include `bulk_messaging/view/message_composition_bulk_messaging.dart:406`, `presentation/messaging/view/staff_messaging_thread.dart:1501, 1527`, `presentation/messaging/widgets/full_attachment_viewer.dart:259`, and several `const TextStyle(color: AppColors.messaging…)` at `admin_chat_host_screen.dart:894`, `conversation_list_screen.dart:425`, `conversation_thread_screen.dart:1556`, `conversation_filter_sheet.dart:386`.
- **Why:** even where the *colour* is a token, constructing a fresh `TextStyle` violates "never a fresh `TextStyle` — use `.copyWith()` on a named style." A method-built `TextStyle` also can't be shared or themed centrally.
- **Severity: Medium** — cosmetic-adjacent but the exact pattern the mandate forbids; ~10 sites.
- **Fix:** replace each with `AppTextStyles.<slot>.copyWith(color: …)`.

**4.2 — `fontFamily: 'Manrope'` hard-coded** · Low
- `shared/widgets/message_bubble_widget.dart:1349, 1425`.
- **Why:** the rule says the family is already on `ThemeData` and these lines are "a find-and-delete." **This module documents an intentional exception**: the message bubble can be re-parented into an `Overlay` (long-press reactions) where the ambient theme is lost, so it carries the family explicitly. That is a defensible reason, but it is still a literal breach of the rule.
- **Severity: Low** — documented exception; behaviour-preserving either way.
- **Fix:** confirm the overlay actually drops the theme; if so keep with an inline `// Mandate 4 exception:` note, else delete.

**4.3 — Raw `Colors.*` / `Color(0x…)` in author-driven widgets** · Low
- `presentation/messaging/widgets/rich_text_toolbar.dart:235-236, 312, 350` (`Colors.white`, `Color(0xFFE2E8F0)`), plus `Colors.transparent` in `rich_text_toolbar.dart` and `shared/utils/html_aware_text_controller.dart:177`.
- **Why:** outside `app_colors.dart`. The refactor deliberately left `rich_text_toolbar.dart` and `html_aware_text_controller.dart` untouched as author-driven rich-text styling; `Colors.transparent` is idiomatic but still matches the rule text.
- **Severity: Low** — narrow, intentional deferral.
- **Fix:** tokenize the toolbar hexes into `AppColors` when the rich-text widgets are next touched; `Colors.transparent` can be an allowed exception (open question).

---

### Mandate 5 — Presentation talks to cubits only — **Partially violated**

**Rule** (§"MANDATE 5"; PDF §5.3): forbidden anywhere under `lib/presentation` — `serviceLocator<T>()` (except in a `GoRoute` builder), `DataSource`/`Repository`/`ApiClient`/`Dio`/**`StorageService`**/`SharedPreferences` types, direct use-case invocation from a view, direct platform calls, and *"`FutureBuilder` / `StreamBuilder` over data the cubit already owns."* Flow: `View → Cubit → UseCase → Repository → DataSource → API`.

`serviceLocator` is clean (the only 3 textual hits are comments asserting its absence). Residuals:

**5.1 — Cubits hold `StorageService` directly** · Medium
- `cubit/communication_cubit.dart:68`, `cubit/staff_messaging_filter_cubit.dart:11, 20`, `cubit/conversation_thread_cubit.dart:78, 123`, `cubit/conversation_list_cubit.dart:32, 50`, `bulk_messaging/cubit/bulk_messaging_composition_cubit.dart:136, 164`.
  ```dart
  final StorageService storageService;   // communication_cubit.dart:68
  ```
- **Why:** cubits are under `lib/presentation`, where `StorageService` is a forbidden type. Reading storage directly in a cubit also skips the `UseCase → Repository` hops the flow prescribes.
- **Severity: Medium** — injected (not `serviceLocator`), low behavioural risk, but a clear layering breach across five core cubits.
- **Fix:** wrap the specific reads (e.g. current user/school code, filter persistence) in use-cases or a domain-side settings service and inject that instead of `StorageService`.

**5.2 — A service lives in presentation and holds `StorageService`** · Medium
- `shared/utils/chat_attachment_uploader.dart:35` — `final StorageService _storage;`
- **Why:** an upload service under `lib/presentation` holding `StorageService` is doubly outside the layer (a service in presentation + a forbidden type). Ties to Mandate 3.3.
- **Severity: Medium.**
- **Fix:** move the uploader into `data/`/`core/services` behind an injected interface the cubit calls via a use-case.

**5.3 — `FutureBuilder` over data a cubit should own** · Medium
- `presentation/messaging/view/screens/open_conversation_screen.dart:77` — `FutureBuilder<ConversationEntity?>`; `shared/widgets/message_info_dialog.dart:177` — `FutureBuilder<List<MessageInfoRecipient>>` (delivery receipts).
- **Why:** a conversation entity and message receipts are domain data that belongs in a cubit's state, not fetched inline in `build()`.
- **Severity: Medium.**
- **Fix:** load in the owning cubit and render via `BlocBuilder`/`BlocSelector`.
- **Not counted as violations:** the four `FutureBuilder<Uint8List>` sites (`message_bubble_widget.dart:1843`, `full_attachment_viewer.dart:512`, `show_full_screen_media_view.dart:488`, `attachment_url_resolver.dart:138`) decode local image bytes via an injected downloader — arguably view-local media rendering rather than cubit-owned data. **Open question — see §6.**

---

### Mandate 6 — Reuse what exists; pure functions out of build() — **Violated**

**Rule** (§"MANDATE 6"; PDF §6.5): *"Replace `Widget _buildXxx()` methods with private `StatelessWidget` classes."* … *"File size ceiling: 400 lines. Split by extracting cohesive units."* … *"Delete commented-out code."* … *"No two classes in the codebase share a name."*

**6.1 — 28 non-generated files exceed the 400-line ceiling** · High
- Worst: `presentation/messaging/view/parent_messaging_thread.dart` **4,239**, `shared/widgets/message_bubble_widget.dart` **2,332**, `presentation/messaging/view/screens/conversation_thread_screen.dart` **2,051**, `presentation/messaging/view/staff_messaging_thread.dart` **1,867**, `presentation/messaging/view/staff_messaging_tab.dart` **1,837**, `cubit/communication_cubit.dart` **1,604**, `cubit/conversation_thread_cubit.dart` **1,557**, `admin_chat_host_screen.dart` **1,299**, `staff_or_student_selection_bulk_messaging.dart` **1,082**, `conversation_list_screen.dart` **1,036**, `chat_input_bar.dart` **1,029**, `communication_repository_impl.dart` **1,028** … 28 in total.
- **Why:** every one is >2.5× the ceiling; five are >4× and one >10×. This is the module's dominant maintenance risk — the standard's rationale (a bug fix requires reading the whole file) is acute at 4,239 lines.
- **Severity: High** — pervasive; directly drives the "worst offender" scorecard rank.
- **Fix:** split by cohesive unit — extract the thread screens' bottom bar, header, and message-list sections into their own files/widgets; split `communication_cubit` by concern (conversations vs messages vs reactions). Sequence carefully (see §5, Remediation).

**6.2 — 35 `Widget _buildXxx()` methods remain** · Medium
- Concentrated in `conversation_thread_screen.dart` (7), `message_bubble_widget.dart` (6), `parent_messaging_thread.dart` (6), `staff_messaging_thread.dart` (5), `parent_direct_messaging_screen.dart` (4).
- **Why:** a method returning a Widget can't be `const`, can't take a `key`, and rebuilds with its whole enclosing widget. The refactor extracted the *self-contained* ones and left the *state-coupled* ones under the rule's own "do not abstract for its own sake" — but 35 is still a lot, and the largest screens are where it matters most.
- **Severity: Medium** — performance + readability; overlaps with 6.1 (splitting the files will naturally absorb most of these).
- **Fix:** as each oversized file is split, promote its `_build*` methods to private `StatelessWidget`s taking the state they need as constructor params.

**6.3 — Residual commented-out code** · Low
- ~16 code-shaped `//` lines remain (e.g. `bulk_messaging/view/message_composition_bulk_messaging.dart:575`, `shared/widgets/message_attachment_bottom_sheet.dart:375, 381`).
- **Severity: Low.**
- **Fix:** delete; keep prose comments.

*(No same-name class collisions were found within the module. The new typed classes `MessagingRecipient`, `StaffThreadInfo`, `ParentThreadInfo` are unique.)*

---

### Mandate 7 — One responsive source — **Partially violated**

**Rule** (§"MANDATE 7"; PDF §7.2): *"`MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` — `.of` subscribes to the whole object, so a width read re-runs on every keyboard open."* Breakpoints live once in `core/responsive/app_breakpoints.dart`; a feature `LayoutBuilder` is allowed only when a widget must respond to its own box.

The **size** reads are already correct — 11 `MediaQuery.sizeOf` uses, and no width comparisons against literal breakpoints in feature code. Residual:

**7.1 — 12 `MediaQuery.of(context)` calls for non-size reads** · Low
- All 12 read `.padding.bottom`, `.viewInsets.bottom`, or `.orientation` — e.g. `staff_messaging_thread.dart:333, 464, 677`, `parent_messaging_thread.dart:412, 1045`, `conversation_thread_screen.dart:607, 2017`, `messaging_entry_screen.dart:68`, `admin_chat_filter_sheet.dart:72`.
- **Why:** the mandate's letter targets *size* reads (done). But its rationale — `.of` subscribes to the whole `MediaQueryData` and rebuilds on keyboard open — applies equally to these; Flutter offers `MediaQuery.viewInsetsOf` / `paddingOf` / `orientationOf` that subscribe to just the aspect read.
- **Severity: Low** — micro-optimization; behaviour identical.
- **Fix:** swap each to the matching `*Of` accessor. **Ambiguity flagged:** the rule names only size reads, so whether these count is a judgment call — see §6.

**7.2 — `chat_thread_shimmer.dart:79` (`width > 160`)** — **not a violation.** The comparison is against the widget's own box width inside a shimmer placeholder, which the rule explicitly permits ("respond to its own box rather than the screen"). Listed here per the rule's requirement to name each retained box-relative comparison.

---

### Mandate 8 — Models everywhere, generated, never raw maps — **Compliant**

**Rule** (§"MANDATE 8"; PDF §8): every payload (requests too) has an `@JsonSerializable()` model with generated `fromJson`/`toJson`; *"No `Map<String, dynamic>` in `lib/domain` or `lib/presentation`."*

- **Zero** `Map<String, dynamic>` in the module's domain or presentation code. The three textual hits are doc comments in `model/thread_info.dart:5, 38` and `model/messaging_recipient.dart:9` describing the maps those typed classes *replaced*.
- Generated models present across `data/features/communication/models/` (`conversation_model`, `conversation_entity_dto`, `communication_settings_model`, `message_entity_dto` sub-DTOs, response envelopes), each with a committed `.g.dart`.
- **Request models present** as the rule demands: `create_conversation_request.dart`, `edit_message_request.dart`, `message_reaction_request.dart`, `send_message_request.dart`.
- Domain entities carry no serialization (verified). Presentation map-shaped payloads are gone (`MessagingRecipient`, `StaffThreadInfo`, `ParentThreadInfo`).

**Documented, allowed exceptions** (hand-written parsers retained *with reasons*, which the rule permits when generation is impossible, each covered by an old-vs-new characterization test in `test/data/features/communication/models/`): `message_model.dart` (runtime ownership param + multi-field derivation), `message_entity_dto.dart` (cross-field sibling-key dependency), `MessageFirestoreItem` (needs `doc.id` outside the map + Firestore `Timestamp`s). The Isar collection `.g.dart` files are Isar-generated, not JSON, and are correctly left as-is. No violations.

---

## 5. Remediation order

Sequenced so each step is a single isolated change that preserves behaviour, cheapest/safest first:

1. **Mandate 6.3 — delete commented-out code** (~16 lines). Zero risk; clears noise before the big splits.
2. **Mandate 4.1 — fresh `TextStyle(` → `AppTextStyles.<slot>.copyWith(...)`** (~10 sites). Localized; light-mode render must stay identical.
3. **Mandate 7.1 — `MediaQuery.of` → `viewInsetsOf`/`paddingOf`/`orientationOf`** (12 sites). Mechanical; behaviour identical. *(Confirm it's in scope — §6.)*
4. **Mandate 5.3 — move the two data `FutureBuilder`s (conversation entity, receipts) into their cubits.** Verify network call counts are unchanged entering/leaving the screen.
5. **Mandate 5.1 / 5.2 — wrap `StorageService` reads behind use-cases / a domain settings service; relocate `chat_attachment_uploader` out of presentation.** One cubit at a time; assert identical behaviour.
6. **Mandate 3.4 — convert all 82 relative cross-folder imports to `package:wowcare/...`.** One pass, analyzer + full test suite green before/after (this is the latent test-breakage fix, so do it before further moves).
7. **Mandate 3.3 — relocate `util/` contents** (mappers → `data/mappers/`, formatters → `core/extensions/`), which also resolves part of 5.2.
8. **Mandate 6.1 / 6.2 — split the 28 oversized files, promoting `_build*` methods to `StatelessWidget`s as you go.** Biggest effort; do file-by-file, largest first (`parent_messaging_thread.dart`), each behind a green test run. Add characterization tests for the thread screens first — they currently carry the most untested logic.
9. **Mandate 3.1 — collapse `communication/presentation/messaging/` up one level**, then **3.2 (`cubit/`→`view_model/`) and 3.5 (fold the `messaging` feature tree)** — but only as part of the **app-wide** rename, not this module alone (the rule says so). Do last, when the app coordinates it.

---

## 6. Open questions

1. **`Map<String, dynamic>` doc-comment scanning.** Findings here treat comment-only matches as non-violations. Confirm sibling audits do the same so counts are comparable.
2. **Mandate 7 non-size `MediaQuery.of`.** The rule's text targets *size* reads; `.padding`/`.viewInsets`/`.orientation` via `.of` are only implicated by its *rationale*. Should these count as violations across all module audits, or be treated as compliant? (This audit scored them Low/Partial; a ruling makes the reports consistent.)
3. **Mandate 5 media `FutureBuilder<Uint8List>`.** Are view-local image-byte decodes (via an injected downloader) "data the cubit already owns"? This audit says no (not counted). Needs a shared ruling.
4. **`Colors.transparent`.** Idiomatic but matches the Mandate-4 text. Allowed exception or must-tokenize?
5. **The `communication` vs `messaging` feature split (3.5).** Is `messaging` (feature flags, filtered staff) intentionally a separate cross-cutting feature, or should it fold into `communication`? This decides whether the cross-`messaging` imports are a violation or by design.
6. **`fontFamily: 'Manrope'` overlay exception (4.2).** Does re-parenting the message bubble into an `Overlay` actually drop the ambient theme? If yes, the two lines are a legitimate documented exception; if no, they are a find-and-delete.
7. **`cubit/` → `view_model/` and the double-nested `presentation/` (3.1/3.2).** The rule flags the rename as app-wide (17/19 features). Confirm these are tracked as a platform task, not charged against this module in isolation.
