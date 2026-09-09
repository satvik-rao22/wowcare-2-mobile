/// Two decisions the Activity Feed tabs used to make inline, extracted as pure
/// functions so the rules are directly testable and so the Daily and Custom
/// tabs cannot drift apart on them.
///
/// Both exist because of the same class of bug: a notification deep-link
/// arrives, the tab mounts, and the screen renders something wrong for the
/// window before its asynchronous bootstrap has produced an answer.
library;

/// Whether the feed should render its loading placeholder rather than the
/// "No Activities found" empty state.
///
/// "No activities" is only ever true of a *specific* question — this child,
/// this day, this room. [hasCurrentResult] is what says the rows on screen
/// answer the question currently being asked; until then an empty list means
/// "we don't know yet", not "there are none".
///
/// Two distinct windows used to leak the empty state, and both are this same
/// mistake:
///
///   * **Before the first load.** All three of the old conditions were
///     innocently false — the cubit doesn't exist yet so [isLoading] falls
///     back to `ActivityFeedState.initial()`'s `false`,
///     [isLoadingParentContext] is only set once the guardian bootstrap is
///     genuinely running, and the item list is trivially empty. The window
///     spans a timezone resolve and several storage reads.
///   * **On a deep link into an already-open tab.** The Activities tab is
///     keep-alive inside an `IndexedStack`, so when the route key doesn't
///     change the previous visit's State is reused — with its completed,
///     now-stale empty result. The screen answered the OLD question while the
///     new one was still being asked, which is why a notification tap showed
///     "No Activities found" and only then started loading.
///
/// So callers must clear [hasCurrentResult] the moment they decide to
/// (re)load — synchronously, before any await — and set it again only when a
/// load has actually finished.
///
/// [hasBootstrapError] is the deliberate exception: a bootstrap-level failure
/// (no school selected, guardian profile unresolvable) is a terminal answer,
/// not work in progress, so it must fall through to the message branch — which
/// renders the error text in place of the empty string. It is also what stops
/// a dead end from spinning forever, since every dead end sets one.
bool shouldShowActivityFeedLoadingPlaceholder({
  required bool isLoading,
  required bool isLoadingParentContext,
  required bool hasCurrentResult,
  required bool hasBootstrapError,
}) {
  if (isLoading || isLoadingParentContext) return true;
  return !hasCurrentResult && !hasBootstrapError;
}

/// The child a GUARDIAN's feed should load, given everything known at bootstrap.
///
/// Precedence:
///
///   1. **[deepLinkStudentCode]** — the subject of the notification the user
///      tapped, and the only source available before `ParentChildCubit` has
///      caught up. A killed-state tap routes straight from the splash, and a
///      tap that crosses a school switch resets the cubit, so in both cases
///      [selectedChildCode] still names the previous child (or none) at the
///      moment the feed bootstraps. It is consumed once
///      ([deepLinkAlreadyApplied]) because it describes a tap, not a standing
///      override — otherwise a later re-bootstrap would resolve back to the
///      notification's child and fight the dropdown the user just used.
///   2. **[selectedChildCode]** — the app-bar switcher, for ordinary browsing
///      and for any deep link that carries no student.
///   3. **the first owned child** — so a selection that resolves to nothing
///      still scopes the feed to ONE child. Skipping the narrowing instead made
///      the guardian fan-out query EVERY child, producing a merged list that
///      then visibly shrank.
///
/// Every candidate is filtered through [ownedStudentCodes] — the guardian's own
/// student list, freshly fetched — so a code that is not one of their children
/// (a stale persisted selection, a forged or replayed payload) is ignored
/// rather than queried. This is a client-side scoping rule, not the
/// authorization boundary; the backend remains that.
///
/// Matching is case-insensitive but the returned value is the canonical code
/// from [ownedStudentCodes], since that is what keys the per-student fan-out.
/// Returns null only when [ownedStudentCodes] is empty.
String? resolveGuardianFeedStudentCode({
  required String? deepLinkStudentCode,
  required bool deepLinkAlreadyApplied,
  required String? selectedChildCode,
  required Iterable<String> ownedStudentCodes,
}) {
  final owned = ownedStudentCodes
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList(growable: false);
  if (owned.isEmpty) return null;

  String? canonical(String? candidate) {
    final trimmed = (candidate ?? '').trim();
    if (trimmed.isEmpty) return null;
    final upper = trimmed.toUpperCase();
    for (final code in owned) {
      if (code.toUpperCase() == upper) return code;
    }
    return null;
  }

  if (!deepLinkAlreadyApplied) {
    final fromDeepLink = canonical(deepLinkStudentCode);
    if (fromDeepLink != null) return fromDeepLink;
  }

  return canonical(selectedChildCode) ?? owned.first;
}
