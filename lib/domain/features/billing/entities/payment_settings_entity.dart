import 'package:equatable/equatable.dart';

/// Who absorbs the convenience fee for a payment method type.
enum FeePayer { parent, school, unknown }

/// School payment settings from `GET /api/v1/payment/settings?schoolCode=...`.
///
/// Drives two things on the parent side:
/// - which method types are offered in the Forte add-method webview, and
/// - whether the convenience fee is shown on the Pay Now review screen (only
///   when the fee is paid by the parent).
class PaymentSettingsEntity extends Equatable {
  const PaymentSettingsEntity({
    required this.acceptCreditCard,
    required this.creditCardFeePaidBy,
    required this.acceptDebitCard,
    required this.debitCardFeePaidBy,
    required this.acceptAch,
    required this.achFeePaidBy,
    this.schoolCode = '',
  });

  final bool acceptCreditCard;
  final FeePayer creditCardFeePaidBy;
  final bool acceptDebitCard;
  final FeePayer debitCardFeePaidBy;
  final bool acceptAch;
  final FeePayer achFeePaidBy;
  final String schoolCode;

  /// Card brands (Visa/Mastercard/Discover) are offered when either credit or
  /// debit cards are accepted — the webview can't distinguish them up front.
  bool get acceptsCard => acceptCreditCard || acceptDebitCard;

  /// The parent bears the ACH convenience fee → show it on the review screen.
  bool get achFeePaidByParent => achFeePaidBy == FeePayer.parent;

  /// The parent bears the card convenience fee (for whichever card type is
  /// accepted) → show it on the review screen.
  bool get cardFeePaidByParent =>
      (acceptCreditCard && creditCardFeePaidBy == FeePayer.parent) ||
      (acceptDebitCard && debitCardFeePaidBy == FeePayer.parent);

  /// Allowed `cardType` values for the Forte webview `<select>` (the HTML
  /// hides any option not in this list).
  List<String> get allowedMethods => <String>[
        if (acceptsCard) 'visa',
        if (acceptsCard) 'mast',
        if (acceptsCard) 'disc',
        if (acceptAch) 'echeck',
      ];

  /// Permissive fallback used until real settings load (or when they fail):
  /// accept every method and assume the parent pays the fee, so nothing is
  /// hidden and no fee is silently dropped.
  static const PaymentSettingsEntity fallback = PaymentSettingsEntity(
    acceptCreditCard: true,
    creditCardFeePaidBy: FeePayer.parent,
    acceptDebitCard: true,
    debitCardFeePaidBy: FeePayer.parent,
    acceptAch: true,
    achFeePaidBy: FeePayer.parent,
  );

  @override
  List<Object?> get props => [
        acceptCreditCard,
        creditCardFeePaidBy,
        acceptDebitCard,
        debitCardFeePaidBy,
        acceptAch,
        achFeePaidBy,
        schoolCode,
      ];
}
