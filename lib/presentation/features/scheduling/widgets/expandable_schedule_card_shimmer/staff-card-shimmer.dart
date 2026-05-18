import 'package:flutter/material.dart';
import '../../../../../shared/common/widgets/custom_shimmer_loader.dart';

/// ===============================
/// STAFF CARD SHIMMER
/// ===============================

class StaffCardShimmer extends StatelessWidget {
  const StaffCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33162831)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          /// TOP PROFILE SECTION
          Row(
            children: [
              /// Avatar
              ShimmerLoader(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),

              const SizedBox(width: 12),

              /// Name + Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoader(height: 16, width: 140),

                    const SizedBox(height: 8),

                    ShimmerLoader(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.25,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              /// Right Text
              ShimmerLoader(
                height: 14,
                width: 80,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// HOURS CARDS
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  children: [
                    ShimmerLoader(
                      height: 22,
                      width: 22,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ShimmerLoader(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.3,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    ShimmerLoader(
                      height: 16,
                      width: 45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// ===============================
/// SCHEDULE CARD SHIMMER
/// ===============================

class ScheduleCardShimmer extends StatelessWidget {
  const ScheduleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33162831)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const ShimmerLoader(height: 16, width: 60),

                const Spacer(),

                ShimmerLoader(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.28,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// TIMELINE ROWS
          ...List.generate(10, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  /// Time
                  ShimmerLoader(
                    height: 28,
                    width: 80,
                    borderRadius: BorderRadius.circular(4),
                  ),

                  const SizedBox(width: 12),

                  /// Schedule Block
                  Expanded(
                    child: ShimmerLoader(
                      height: 28,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
