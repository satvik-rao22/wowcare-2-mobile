# Reports Module — Performance Notes

Scope note: this pass was a code-review-level check (rebuild structure, keep-alive usage, duplication), not an instrumented profiling session (no DevTools timeline was captured). Treat findings as review-level, not measured.

## Findings

- `GeneratedReportsScreen` uses `AutomaticKeepAliveClientMixin` (`generated_reports_screen.dart:28,32`) to persist its tab's state across switches — appropriate for avoiding re-fetching the generated-reports list on every tab visit, but see `REPORTS_LIFECYCLE_ISSUES.md` for the tradeoff with stale-frame risk after external-app resume.
- Download/open/save logic for report files is duplicated across `reports_screen.dart:704-813` and `generated_reports_screen.dart:51-217` rather than shared, which is a maintainability issue more than a runtime performance one, but duplicated logic paths increase the chance of divergent (and less optimized) implementations over time. See `REPORTS_BUGS.md` #5.
- No obvious N+1 API call pattern was found in the cubit — report generation and recent-report fetches are each single request/response cycles per user action, not per-item.

## Not fully assessed in this pass
Widget rebuild counts, BlocBuilder nesting depth per screen, and const-constructor coverage were not exhaustively measured (would require running the app with DevTools' widget rebuild stats). Recommend a follow-up profiling pass before final release sign-off if performance is a release blocker, rather than relying solely on this static review.
