import 'package:flutter/material.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../shared/common/widgets/gredient-minimze-button.dart';

class MovementsCard extends StatefulWidget {
  const MovementsCard({super.key});

  @override
  State<MovementsCard> createState() => _MovementsCardState();
}

class _MovementsCardState extends State<MovementsCard> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              const Text(
                'Movements',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4B2D52),
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.north_east_rounded,
                color: AppColors.themeColor.withOpacity(0.75),
                size: 26,
              ),

              const Spacer(),

              GradientToggleButton(
                minimized: _minimized,
                onTap: () {
                  setState(() {
                    _minimized = !_minimized;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 26),

          if (!_minimized) ...[
            _buildMovementItem(
              month: 'Dec',
              day: '01',
              studentCount: '2 students',
              roomText: '1-Blue-D › 2-Green-D',
              status: 'Overdue',
              statusColor: Colors.red,
              statusBg: const Color(0xffFCEAEA),
              lineColor: const Color(0xffB993FF),
              avatars: const [
                _AvatarData(color: Color(0xffD9687A), text: ''),
                _AvatarData(color: Color(0xffF2BE6B), text: '+1'),
              ],
            ),

            const SizedBox(height: 34),

            _buildMovementItem(
              month: 'Jan',
              day: '08',
              studentCount: '3 students',
              roomText: '3-Purple-D › 4-Yellow-D',
              status: 'Upcoming',
              statusColor: Color(0xffC79A00),
              statusBg: Color(0xffF8F0CF),
              lineColor: Color(0xffFFA781),
              avatars: const [
                _AvatarData(color: Color(0xff77C2FF), text: ''),
                _AvatarData(color: Color(0xffA7A4E8), text: 'SL'),
              ],
            ),

            const SizedBox(height: 34),

            _buildMovementItem(
              month: 'Feb',
              day: '12',
              studentCount: '2 students',
              roomText: '6-Pink-P › 7-Yellow-P',
              status: 'Confirmed',
              statusColor: Color(0xff2DBD60),
              statusBg: Color(0xffE4F5E8),
              lineColor: Color(0xff7BD48C),
              avatars: const [
                _AvatarData(color: Color(0xff67B4F0), text: '3('),
                _AvatarData(color: Color(0xffA7A4E8), text: '2C'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMovementItem({
    required String month,
    required String day,
    required String studentCount,
    required String roomText,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required Color lineColor,
    required List<_AvatarData> avatars,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// DATE SECTION
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 44,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff3F4050),
                  ),
                ),
              ],
            ),
          ),

          /// VERTICAL LINE
          Container(
            width: 4,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          /// CENTER CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// STUDENTS + STATUS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          studentCount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff3F4050),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// ROOM TEXT
                  Text(
                    roomText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff4A4A5B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// AVATAR SECTION
          SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  child: _buildAvatar(
                    color: avatars[0].color,
                    text: avatars[0].text,
                  ),
                ),

                if (avatars.length > 1)
                  Positioned(
                    left: 10,
                    child: _buildAvatar(
                      color: avatars[1].color,
                      text: avatars[1].text,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required Color color, required String text}) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _AvatarData {
  final Color color;
  final String text;

  const _AvatarData({required this.color, required this.text});
}
