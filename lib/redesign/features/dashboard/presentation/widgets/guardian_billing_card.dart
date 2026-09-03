import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/billing_card.dart';

/// What a guardian owes, and what they have already paid (3P2).
///
/// The balance is the one figure on the card that gets the big type, and Pay
/// now is the one pink key on the screen.
class GuardianBillingCard extends StatelessWidget {
  const GuardianBillingCard({
    required this.billing,
    required this.onPayNow,
    required this.onOpenInvoices,
    super.key,
  });

  final GuardianBilling billing;
  final VoidCallback onPayNow;
  final VoidCallback onOpenInvoices;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.cardContentGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.balanceDue,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              StatusPill(
                label: DashboardStrings.dueOn(billing.dueLabel),
                tone: billing.isSettled ? PillTone.success : PillTone.staff,
                small: true,
              ),
            ],
          ),
          Text(
            billing.isSettled
                ? DashboardStrings.nothingDue
                : BillingCard.money(billing.balanceDue, compact: false),
            style: DashboardTextStyles.balanceAmount.copyWith(color: c.ink),
          ),
          Text(
            DashboardStrings.tuitionAutopay(
              billing.monthLabel,
              autopayOn: billing.isAutopayOn,
            ),
            style: DashboardTextStyles.balanceSub.copyWith(color: c.ink3),
          ),
          if (!billing.isSettled)
            PrimaryKey(
              label: DashboardStrings.payNow,
              padding: DashboardSizes.payNowPad,
              onTap: onPayNow,
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.invoices,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              TextLink(
                label: DashboardStrings.all,
                color: c.student,
                onTap: onOpenInvoices,
              ),
            ],
          ),
          for (final invoice in billing.invoices) _Invoice(invoice: invoice),
        ],
      ),
    );
  }
}

class _Invoice extends StatelessWidget {
  const _Invoice({required this.invoice});

  final InvoiceRow invoice;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.altWell(c),
      padding: DashboardSizes.dayRowPad,
      child: Row(
        spacing: DashboardSizes.messageRowGap,
        children: <Widget>[
          Icon(
            AppIcons.receipt,
            size: DashboardSizes.rangeWellGlyph,
            color: c.ink3,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  invoice.title,
                  style: DashboardTextStyles.invoiceTitle.copyWith(
                    color: c.ink,
                  ),
                ),
                Text(
                  invoice.meta,
                  style: DashboardTextStyles.invoiceSub.copyWith(
                    color: c.ink3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            BillingCard.money(invoice.amount, compact: false),
            style: DashboardTextStyles.invoiceAmount.copyWith(color: c.ink),
          ),
        ],
      ),
    );
  }
}
