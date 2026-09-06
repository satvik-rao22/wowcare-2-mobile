import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/theme/fonts.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_student_card.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

/// Renders the per-family billing summary rows (used by both the Student(s)
/// overview list and the Transactions list) as [BillingStudentCard]s.
class FamilySummaryList extends StatelessWidget {
  const FamilySummaryList({
    super.key,
    required this.families,
    required this.isLoading,
    this.errorMessage,
    this.showSelection = false,
    this.onBillingProfile,
  });

  final List<FamilySummaryEntity> families;
  final bool isLoading;
  final String? errorMessage;
  final bool showSelection;
  final void Function(FamilySummaryEntity family)? onBillingProfile;

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  String _formatDate(DateTime? date) =>
      date == null ? '-' : _dateFormat.format(date);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Card-shaped skeletons (matching BillingStudentCard / staff card) so the
      // list area shows structure while the family summary loads.
      return Column(
        children: List.generate(
          5,
          (_) => const BillingTransactionShimmer(),
        ),
      );
    }
    if (errorMessage != null && families.isEmpty) {
      // Detail goes to the top snackbar; keep the list area calm.
      return const _Message(text: BillingStrings.couldntLoadFamilies);
    }
    if (families.isEmpty) {
      return const _Message(text: BillingStrings.noFamiliesFound);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final family in families)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BillingStudentCard(
              name: family.familyName.trim().isNotEmpty
                  ? family.familyName
                  : family.guardianName,
              classroom: family.guardianName,
              fileUuid: '',
              amount: family.lastPaymentAmount,
              paidOn: _formatDate(family.lastPaymentDate),
              paymentMethod: family.lastPaymentMethod,
              paymentNote: '',
              lastPaymentStatus: family.lastInvoiceStatus,
              lastInvoiceAmount: family.lastInvoiceAmount,
              lastInvoiceSent: _formatDate(family.lastInvoiceDate),
              lastInvoiceDue: _formatDate(family.lastInvoiceDueDate),
              openBalance: family.openBalance,
              showSelection: showSelection,
              onBillingProfile: onBillingProfile == null
                  ? null
                  : () => onBillingProfile!(family),
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: Fonts.manrope,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.billingTextColor,
          ),
        ),
      ),
    );
  }
}
