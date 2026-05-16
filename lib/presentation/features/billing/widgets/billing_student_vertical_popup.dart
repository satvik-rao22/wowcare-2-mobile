import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_details_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';

enum BillingPopupType { student, invoice, payment }

class BillingStudentVerticalPopUp extends StatelessWidget {
  const BillingStudentVerticalPopUp({
    super.key,
    this.popupType = BillingPopupType.student,
    this.onMessageTap,
    this.onBillingProfileTap,
    this.onClose,
    this.onViewTap,
    this.onEditTap,
    this.onResendTap,
    this.onReceivePaymentTap,
    this.onIssueRefundTap,
    this.onMoreTap,
    this.transaction,
  });

  final BillingPopupType popupType;
  final VoidCallback? onMessageTap;
  final VoidCallback? onBillingProfileTap;
  final VoidCallback? onClose;
  final VoidCallback? onViewTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onResendTap;
  final VoidCallback? onReceivePaymentTap;
  final VoidCallback? onIssueRefundTap;
  final VoidCallback? onMoreTap;
  final TransactionItem? transaction;

  @override
  Widget build(BuildContext context) {
    final List<_PopupActionConfig> actions = _buildActions(context);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Material(
          borderRadius: BorderRadius.circular(10),
          elevation: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions.length; i++) ...<Widget>[
                  _PopupActionButton(
                    iconPath: actions[i].iconPath,
                    label: actions[i].label,
                    onTap: actions[i].onTap,
                  ),
                  if (i != actions.length - 1) const SizedBox(height: 18),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 15),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(156, 132, 255, 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClose,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_PopupActionConfig> _buildActions(BuildContext context) {
    final VoidCallback? defaultBillingProfileTap =
        onBillingProfileTap ?? _buildDefaultBillingProfileTap(context);
    switch (popupType) {
      case BillingPopupType.student:
        return <_PopupActionConfig>[
          _PopupActionConfig(
            iconPath: MediaRes.message_panel_icon,
            label: 'Message',
            onTap: onMessageTap,
          ),
          _PopupActionConfig(
            iconPath: MediaRes.profile_panel_icon,
            label: 'Billing Profile',
            onTap: defaultBillingProfileTap,
          ),
        ];
      case BillingPopupType.invoice:
        return <_PopupActionConfig>[
          _PopupActionConfig(
            iconPath: MediaRes.docsIcon,
            label: 'View',
            onTap: onViewTap,
          ),
          _PopupActionConfig(
            iconPath: MediaRes.communicationIcon,
            label: 'Edit',
            onTap: onEditTap,
          ),
          _PopupActionConfig(
            iconPath: MediaRes.redirectArrowGradientIcon,
            label: 'Resend',
            onTap: onResendTap,
          ),
          _PopupActionConfig(
            iconPath: MediaRes.transactions_Billing_Drawer_Icon,
            label: 'Receive Payment',
            onTap: onReceivePaymentTap,
          ),
          _PopupActionConfig(
            iconPath: MediaRes.moreIcon,
            label: 'More',
            onTap: onMoreTap,
          ),
        ];
      case BillingPopupType.payment:
        return <_PopupActionConfig>[
          _PopupActionConfig(
            iconPath: MediaRes.docsIcon,
            label: 'View',
            onTap: onViewTap,
          ),
          _PopupActionConfig(
            iconPath: MediaRes.transactions_Billing_Drawer_Icon,
            label: 'Issue Refund',
            onTap: onIssueRefundTap,
          ),
          _PopupActionConfig(
            iconPath: MediaRes.moreIcon,
            label: 'More',
            onTap: onMoreTap,
          ),
        ];
    }
  }

  VoidCallback? _buildDefaultBillingProfileTap(BuildContext context) {
    return _transactionDetailsOpener(context, transaction);
  }
}

class _PopupActionConfig {
  const _PopupActionConfig({
    this.iconPath,
    this.iconData,
    required this.label,
    this.onTap,
  }) : assert(iconPath != null || iconData != null);

  final String? iconPath;
  final IconData? iconData;
  final String label;
  final VoidCallback? onTap;
}

class _PopupActionButton extends StatelessWidget {
  const _PopupActionButton({
    this.iconPath,
    this.iconData,
    required this.label,
    this.onTap,
  }) : assert(iconPath != null || iconData != null);

  final String? iconPath;
  final IconData? iconData;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPath != null)
                SvgPicture.asset(
                  iconPath!,
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                )
              else if (iconData != null)
                Icon(iconData, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BillingMoreOptionsPopup extends StatelessWidget {
  const BillingMoreOptionsPopup({
    super.key,
    required this.popupType,
    this.onMessageTap,
    this.onBillingProfileTap,
    this.onCancelTap,
    this.transaction,
  });

  final BillingPopupType popupType;
  final VoidCallback? onMessageTap;
  final VoidCallback? onBillingProfileTap;
  final VoidCallback? onCancelTap;
  final TransactionItem? transaction;

  @override
  Widget build(BuildContext context) {
    final List<_PopupActionConfig> actions = <_PopupActionConfig>[
      _PopupActionConfig(
        iconPath: MediaRes.message_panel_icon,
        label: 'Message',
        onTap: onMessageTap,
      ),
      _PopupActionConfig(
        iconPath: MediaRes.profile_panel_icon,
        label: 'Billing Profile',
        onTap:
            onBillingProfileTap ??
            _transactionDetailsOpener(context, transaction),
      ),
      if (popupType == BillingPopupType.invoice)
        _PopupActionConfig(
          iconData: Icons.close,
          label: 'Cancel',
          onTap: onCancelTap,
        ),
    ];

    return Container(
      width: 80,
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(111, 140, 255, 1)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: _MoreOptionItem(
                  iconPath: action.iconPath,
                  iconData: action.iconData,
                  label: action.label,
                  onTap: action.onTap,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MoreOptionItem extends StatelessWidget {
  const _MoreOptionItem({
    this.iconPath,
    this.iconData,
    required this.label,
    this.onTap,
  }) : assert(iconPath != null || iconData != null);

  final String? iconPath;
  final IconData? iconData;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final VoidCallback effectiveOnTap = onTap ?? () {};
    final String displayLabel = label.replaceAll(' ', '\n');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveOnTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _GradientIcon(iconPath: iconPath, iconData: iconData, size: 24),
            const SizedBox(height: 4),
            Text(
              displayLabel,
              maxLines: label.split(' ').length,
              softWrap: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Manrope',
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({this.iconPath, this.iconData, required this.size})
    : assert(iconPath != null || iconData != null);

  final String? iconPath;
  final IconData? iconData;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return AppColors.buildPrimaryGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: iconPath != null
          ? SvgPicture.asset(
              iconPath!,
              height: size,
              width: size,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            )
          : Icon(iconData, size: size, color: Colors.white),
    );
  }
}

VoidCallback? _transactionDetailsOpener(
  BuildContext context,
  TransactionItem? transaction,
) {
  if (transaction == null) {
    return null;
  }
  final TransactionItem transactionItem = transaction;
  return () {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) =>
              TransactionDetailsScreen(transaction: transactionItem),
        ),
      );
    });
  };
}
