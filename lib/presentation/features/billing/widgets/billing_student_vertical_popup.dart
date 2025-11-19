import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

class BillingStudentVerticalPopUp extends StatelessWidget {
  const BillingStudentVerticalPopUp({
    super.key,
    this.onMessageTap,
    this.onBillingProfileTap,
    this.onClose,
  });

  final VoidCallback? onMessageTap;
  final VoidCallback? onBillingProfileTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Material(
          borderRadius: BorderRadius.circular(10),
          elevation: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                _BillingActionButton(
                  svgPath: MediaRes.message_panel_icon,
                  label: 'Message',
                  onTap: onMessageTap,
                ),
                const SizedBox(height: 20),
                _BillingActionButton(
                  svgPath: MediaRes.billing_drawer_icon,
                  label: 'Billing Profile',
                  onTap: onBillingProfileTap,
                ),
                const SizedBox(height: 24),
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
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BillingActionButton extends StatelessWidget {
  const _BillingActionButton({
    required this.svgPath,
    required this.label,
    this.onTap,
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SvgPicture.asset(
            svgPath,
            height: 24,
            width: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

