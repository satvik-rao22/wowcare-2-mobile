import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';

/// Typed `extra` payload for the newsletter preview routes
/// (`NewsletterRoutes.dashboardPreview` / `NewsletterRoutes.messagingPreview`).
///
/// The newsletter's identity travels as a **path parameter**, not in here —
/// that is what makes the route deep-linkable and what the preview screen
/// loads from. This class carries only the optional list-row entity the
/// caller already has in hand, so the preview can paint the title, theme and
/// thumbnail on the first frame instead of showing a spinner while the
/// detail call is in flight.
///
/// `extra` is not serialisable and does not survive a process restart or a
/// browser reload, which is exactly why nothing required lives here: with a
/// null [initialNewsletter] the screen behaves like the notification
/// deep-link — it loads from the code alone and shows the spinner. That is
/// the rule for the other modules too. **Anything a route cannot work
/// without belongs in the path; `extra` is for optimisations and for values
/// that genuinely cannot be a string.**
///
/// [fromExtra] is the only way the router reads this back. It type-tests
/// rather than casting, so a route reached with no `extra` (deep-link,
/// restored stack) degrades to null instead of throwing — Mandate 1's "no
/// untyped casts at the receiving end".
class NewsletterPreviewArgs {
  const NewsletterPreviewArgs({this.initialNewsletter});

  /// The list row that was tapped, if the caller had one. Rendered
  /// immediately while the full newsletter is fetched by code.
  final Newsletter? initialNewsletter;

  /// Reads a [NewsletterPreviewArgs] out of `GoRouterState.extra`, or null if
  /// the route was reached without one.
  static NewsletterPreviewArgs? fromExtra(Object? extra) =>
      extra is NewsletterPreviewArgs ? extra : null;
}
