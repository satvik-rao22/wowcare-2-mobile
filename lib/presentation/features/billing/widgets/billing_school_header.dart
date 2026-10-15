import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/billing/view_model/billing_school_header_cubit.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

/// Shared school header for billing receipt/invoice screens: shows the real
/// school logo-initials avatar, name, tagline, and address.
///
/// The name is read from local storage (always available); the tagline +
/// address are fetched once from `GET /api/v1/schools/{schoolCode}` and cached.
class BillingSchoolHeader extends StatefulWidget {
  const BillingSchoolHeader({super.key, this.avatarSize = 56});

  final double avatarSize;

  @override
  State<BillingSchoolHeader> createState() => _BillingSchoolHeaderState();
}

class _BillingSchoolHeaderState extends State<BillingSchoolHeader> {
  final BillingSchoolHeaderCubit _cubit =
      serviceLocator<BillingSchoolHeaderCubit>();

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillingSchoolHeaderCubit>.value(
      value: _cubit,
      child: BlocBuilder<BillingSchoolHeaderCubit, BillingSchoolHeaderState>(
        builder: (context, data) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                name: data.name,
                size: widget.avatarSize,
                fontSize: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (data.tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.tagline,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                    if (data.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.address,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
