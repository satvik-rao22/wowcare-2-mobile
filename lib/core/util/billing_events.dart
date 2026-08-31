import 'package:flutter/foundation.dart';

/// Lightweight global signal fired after ANY billing mutation (create / edit /
/// delete / cancel / issue / resend an invoice, or record a payment / refund /
/// credit). Any open billing screen listens to [tick] and refreshes so the
/// list, overview totals and ledger always reflect the change — the same idea
/// as [ProfilePhotoUploadEvents] used by the Staff/Student lists.
///
/// Listeners add a listener to [tick] in `initState` and remove it in
/// `dispose`; the invoice repository bumps it after each successful mutation.
class BillingEvents {
  BillingEvents._();

  /// Bumped once per successful billing mutation.
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  /// Fire after a billing mutation succeeds.
  static void notifyChanged() => tick.value++;
}
