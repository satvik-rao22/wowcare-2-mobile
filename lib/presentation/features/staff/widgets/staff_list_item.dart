import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

class StaffListItem extends StatelessWidget {
  const StaffListItem({
    required this.fullName,
    required this.role,
    required this.roomName,
    this.onTap,
    super.key,
  });

  final String fullName;
  final String role;
  final String roomName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorderColor),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.cardColor,
          ),
          child: Row(
            children: [
              ProfileAvatar(name: fullName, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (roomName.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 16,
                            child: VerticalDivider(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              thickness: 0.5,
                              width: 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              roomName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
