import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student_profile.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Opens [ViewInvoiceScreen] for an invoice known only by its CODE — reached
/// from a notification/email deep-link (`INV_GEN_GUARD_EML`'s `paymentUrl`),
/// which carries no in-memory [TransactionItem] the way navigating from a
/// billing list does.
///
/// Fetches the invoice by code (and the student's name, for display) up
/// front so the built [TransactionItem] carries real totals/labels —
/// [ViewInvoiceScreen]'s bottom "Total Amount" always reads `transaction.amount`
/// directly, never the invoice detail it separately re-fetches.
class OpenInvoiceByCodeScreen extends StatefulWidget {
  const OpenInvoiceByCodeScreen({
    super.key,
    required this.invoiceCode,
    this.studentCode,
  });

  static const String routeName = '/billing/invoice-by-code';

  final String invoiceCode;
  final String? studentCode;

  @override
  State<OpenInvoiceByCodeScreen> createState() =>
      _OpenInvoiceByCodeScreenState();
}

class _OpenInvoiceByCodeScreenState extends State<OpenInvoiceByCodeScreen> {
  late final Future<TransactionItem?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TransactionItem?> _load() async {
    final code = widget.invoiceCode.trim();
    if (code.isEmpty) return null;
    try {
      final detail = await serviceLocator<GetInvoiceByCodeUseCase>()(code);
      final base = TransactionItem.fromInvoice(detail, id: 1);

      final studentCode = (widget.studentCode?.trim().isNotEmpty ?? false)
          ? widget.studentCode!.trim()
          : detail.studentCode.trim();
      if (studentCode.isEmpty) return base;

      StudentProfile? profile;
      try {
        profile = await serviceLocator<GetStudentProfileUseCase>()(
          code: studentCode,
        );
      } catch (_) {
        // Name/classroom enrichment is best-effort — the base item (student
        // code as the label) still renders a working invoice screen.
      }
      if (profile == null) return base;

      final name = profile.fullName.trim();
      final classroom = (profile.classroomName ?? '').trim();
      if (name.isEmpty && classroom.isEmpty) return base;

      return TransactionItem(
        id: base.id,
        invoiceCode: base.invoiceCode,
        transactionType: base.transactionType,
        date: base.date,
        amount: base.amount,
        status: base.status,
        description: base.description,
        studentName: name.isNotEmpty ? name : base.studentName,
        classroom: classroom.isNotEmpty ? classroom : base.classroom,
        studentCode: base.studentCode,
        refTable: base.refTable,
        balance: base.balance,
        endDate: base.endDate,
        studentOpenBalance: base.studentOpenBalance,
      );
    } catch (_) {
      return null;
    }
  }

  void _goBackOrHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBackOrHome();
      },
      child: FutureBuilder<TransactionItem?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: PrimaryCircularLoader()),
            );
          }
          final transaction = snapshot.data;
          if (transaction == null) {
            return Scaffold(
              appBar: AppBar(leading: BackButton(onPressed: _goBackOrHome)),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'This invoice could not be found, or you no longer '
                    'have access to it.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          return ViewInvoiceScreen(transaction: transaction);
        },
      ),
    );
  }
}
