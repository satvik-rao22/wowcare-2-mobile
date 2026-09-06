import 'package:flutter/widgets.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_transaction_entity.dart';
import 'package:wowcare/domain/features/billing/entities/payment_settings_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/admin_statements_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/pay_now_authorize_cubit.dart';
import 'package:wowcare/presentation/features/billing/model/auto_pay_webview_payload.dart';
import 'package:wowcare/presentation/features/billing/model/billing_family_member.dart';
import 'package:wowcare/presentation/features/billing/model/discount_account_model.dart';
import 'package:wowcare/presentation/features/billing/model/invoice_draft.dart';
import 'package:wowcare/presentation/features/billing/model/ledger_account_model.dart';
import 'package:wowcare/presentation/features/billing/model/student_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';

/// Typed route argument payloads for the billing GoRouter routes.
///
/// Every billing screen that used to be pushed imperatively is now
/// registered as a GoRoute in `app_router.dart`. Each route reads its arguments
/// from `state.extra` cast to the matching class below — the `extra` object is
/// passed through untouched (never serialized), so it can safely carry
/// non-primitive values and even callbacks/closures.

/// [CreateInvoiceScreen]
class CreateInvoiceArgs {
  const CreateInvoiceArgs({
    required this.selectedStudents,
    this.initialInvoiceData,
  });

  final List<Student> selectedStudents;
  final InvoiceDraft? initialInvoiceData;
}

/// [SelectStudentsScreen]
class SelectStudentsArgs {
  const SelectStudentsArgs({this.invoiceData, this.onNext});

  final InvoiceDraft? invoiceData;
  final void Function(BuildContext context, List<Student> students)? onNext;
}

/// [SelectedStudentsReceiptScreen]
class SelectedStudentsReceiptArgs {
  const SelectedStudentsReceiptArgs({
    required this.selectedStudents,
    required this.invoiceData,
    this.onStudentRemoved,
    this.isConfirmation = false,
    this.onSubmit,
  });

  final List<Student> selectedStudents;
  final InvoiceDraft invoiceData;
  final void Function(Student student)? onStudentRemoved;
  final bool isConfirmation;
  final Future<bool> Function(String mode, List<Student> students)? onSubmit;
}

/// [TransactionDetailsScreen]
class TransactionDetailsArgs {
  const TransactionDetailsArgs({
    this.transaction,
    this.ownerType,
    this.ownerCode,
    this.familyName,
  });

  final TransactionItem? transaction;
  final String? ownerType;
  final String? ownerCode;
  final String? familyName;
}

/// [ReceivePaymentIssueRefundScreen]
class ReceivePaymentRefundArgs {
  const ReceivePaymentRefundArgs({
    required this.transaction,
    this.isRefund = false,
    this.studentCode,
    this.ownerType,
    this.ownerCode,
  });

  final TransactionItem transaction;
  final bool isRefund;
  final String? studentCode;
  final String? ownerType;
  final String? ownerCode;
}

/// [AddCreditScreen]
class AddCreditArgs {
  const AddCreditArgs({
    this.ownerType,
    this.ownerCode,
    this.studentCode,
    this.familyName,
  });

  final String? ownerType;
  final String? ownerCode;
  final String? studentCode;
  final String? familyName;
}

/// [GenerateStatementScreen]
class GenerateStatementArgs {
  const GenerateStatementArgs({
    required this.cubit,
    required this.subscriberCode,
    required this.ownerType,
    this.familyChildren = const [],
  });

  final AdminStatementsCubit cubit;
  final String subscriberCode;
  final String ownerType;
  final List<BillingFamilyMember> familyChildren;
}

/// [ViewInvoiceScreen]
class ViewInvoiceArgs {
  const ViewInvoiceArgs({required this.transaction});

  final TransactionItem transaction;
}

/// [ViewReceiptScreen]
class ViewReceiptArgs {
  const ViewReceiptArgs({
    required this.transaction,
    this.viewType = 'receipt',
  });

  final TransactionItem transaction;
  final String viewType;
}

/// [SendInvoiceScreen]
class SendInvoiceArgs {
  const SendInvoiceArgs({required this.transaction});

  final TransactionItem transaction;
}

/// [PayNowAuthorizeScreen]
class PayNowAuthorizeArgs {
  const PayNowAuthorizeArgs({
    required this.method,
    required this.amount,
    required this.charges,
    required this.settings,
  });

  final PaymentMethodEntity method;
  final double amount;
  final List<PayNowCharge> charges;
  final PaymentSettingsEntity settings;
}

/// [AutoPayTokenWebView]
class AutoPayTokenWebViewArgs {
  const AutoPayTokenWebViewArgs({required this.payload});

  final AutoPayWebviewPayload payload;
}

/// [AutoPayPaymentMethodsScreen]
class AutoPayPaymentMethodsArgs {
  const AutoPayPaymentMethodsArgs({this.isPicker = false});

  final bool isPicker;
}

/// [EditDiscountScreen]
class EditDiscountArgs {
  const EditDiscountArgs({required this.discount});

  final DiscountAccountModel discount;
}

/// [LedgerDetailScreen]
class LedgerDetailArgs {
  const LedgerDetailArgs({required this.ledger});

  final LedgerAccountModel ledger;
}

/// [EditLedgerScreen]
class EditLedgerArgs {
  const EditLedgerArgs({required this.ledger});

  final LedgerAccountModel ledger;
}

/// [AddTransactionScreen]
class AddTransactionArgs {
  const AddTransactionArgs({required this.ledgerCode, required this.onSave});

  final String ledgerCode;
  final Future<bool> Function(AddTransactionParams params) onSave;
}

// `ReportFileViewerArgs` used to be declared here as well as in the reports
// feature — two classes, one name (§6.5). The reports copy is now the single
// declaration, since the viewer screen it describes lives there and is pushed
// from both features. See
// `presentation/features/reports/model/report_route_args.dart`.
