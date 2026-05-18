import 'package:flutter/material.dart';
import '../../../../../shared/common/widgets/custom_shimmer_loader.dart';

class ExpandableScheduleCardShimmer extends StatelessWidget {
  const ExpandableScheduleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33162831)),
      ),
      child: Column(
        children: [
          /// Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFBF8FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Expanded(child: ShimmerLoader(height: 18, width: 120)),

                const SizedBox(width: 16),

                ShimmerLoader(
                  height: 18,
                  width: 80,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          ...List.generate(3, (index) {
            return Column(
              children: [
                /// Classroom Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const ShimmerLoader(height: 16, width: 140),

                            const SizedBox(width: 10),

                            ShimmerLoader(
                              height: 18,
                              width: 18,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ShimmerLoader(
                        height: 24,
                        width: 24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ],
                  ),
                ),

                /// Expanded Staff List
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: List.generate(2, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            /// Avatar
                            ShimmerLoader(
                              height: 40,
                              width: 40,
                              borderRadius: BorderRadius.circular(20),
                            ),

                            const SizedBox(width: 12),

                            /// Name + Hours
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const ShimmerLoader(height: 16, width: 120),

                                  const SizedBox(height: 8),

                                  ShimmerLoader(
                                    height: 12,
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.25,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// Shift Time Box
                            ShimmerLoader(
                              height: 48,
                              width: 110,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
