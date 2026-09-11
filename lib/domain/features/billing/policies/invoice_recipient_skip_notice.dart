import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';

/// Composes the notice shown when `POST /invoices/check-recipients` reports
/// that only SOME of the selected students can be invoiced.
///
/// Why this is a policy rather than an inline string: the banner is rendered
/// through `CoreUtils.showTopSnackBar`, whose warning path runs the message
/// through `ApiErrorHandler.sanitizeMessage`. That sanitizer replaces ANY
/// message longer than 240 characters with the generic "Something went wrong.
/// Please try again." — a guard meant for raw exception dumps.
///
/// Naming every skipped student and repeating the backend's reason once per
/// student produced ~317 characters for a 4-student batch, so the real
/// explanation was silently swallowed and an ordinary partial-eligibility
/// result looked like a crash. The copy is therefore built shortest-that-fits:
/// names are capped with a "+N more" tail, and the reason is only included
/// when the backend returned a single distinct one that still fits.
class InvoiceRecipientSkipNotice {
  InvoiceRecipientSkipNotice._();

  /// Budget for the composed message, with headroom under the sanitizer's
  /// 240-character cliff.
  static const int maxLength = 200;

  /// How many students are named outright before switching to "+N more".
  static const int maxNamed = 2;

  static String build({
    required List<RecipientEligibilityEntity> ineligible,
    required Map<String, String> nameByCode,
    required int totalSelected,
  }) {
    final names = ineligible
        .map((r) => (nameByCode[r.studentCode] ?? r.studentCode).trim())
        .where((n) => n.isNotEmpty)
        .toList();
    final who = names.length <= maxNamed
        ? names.join(', ')
        : '${names.take(maxNamed).join(', ')} +${names.length - maxNamed} more';

    final subject = ineligible.length == 1 ? 'student' : 'students';
    final headline = '${ineligible.length} of $totalSelected $subject skipped';

    final reasons = ineligible
        .map((r) => (r.reason ?? '').trim())
        .where((r) => r.isNotEmpty)
        .toSet();

    // Most detailed form first; fall back until one fits the budget.
    final candidates = <String>[
      if (reasons.length == 1 && who.isNotEmpty)
        '$headline ($who): ${reasons.first}',
      if (reasons.length == 1) '$headline: ${reasons.first}',
      if (who.isNotEmpty) '$headline: $who. Continuing with the rest.',
      '$headline. Continuing with the rest.',
    ];
    return candidates.firstWhere(
      (m) => m.length <= maxLength,
      // The bare headline is short by construction; this is belt-and-braces.
      orElse: () => candidates.last,
    );
  }
}
