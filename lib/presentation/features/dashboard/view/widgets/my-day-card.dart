import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/media_res.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../shared/common/widgets/gredient-minimze-button.dart';

class MyDayCard extends StatefulWidget {
  const MyDayCard({super.key});

  @override
  State<MyDayCard> createState() => _MyDayCardState();
}

class _MyDayCardState extends State<MyDayCard> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF8F8FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        children: [
          /// HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'My Day',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your shift starts in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ],
                ),

                /// STATIC TOGGLE ICON
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
          ),

          /// TIMER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _TimeItem(value: '08', label: 'HH'),
                _TimeSeparator(),
                _TimeItem(value: '24', label: 'MM'),
                _TimeSeparator(),
                _TimeItem(value: '12', label: 'SS'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// REMINDER BUTTON
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xff5978F7), Color(0xff9B84FF)],
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Send Reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// WORK TIME
          _buildChip(label: 'Work Time : 09:00 AM - 06:00 PM'),

          const SizedBox(height: 10),

          /// BREAK TIME
          _buildChip(label: 'Break Time : 01:00 PM - 02:00 PM'),

          const SizedBox(height: 18),

          /// PIN
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [Color(0xff5978F7), Color(0xff9B84FF)],
                  ).createShader(bounds);
                },
                child: const Text(
                  'Your Sign-In Pin: 2481',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffE2E8F0)),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xff5978F7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          /// BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffD1D5DB)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Mark Absent',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff334155),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xff5978F7), Color(0xff9B84FF)],
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Sign-In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// BOTTOM CHAT SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xffEEF2FF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=12',
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sophia Turner',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Don’t forget the meeting at 3 PM.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xff5978F7), Color(0xff9B84FF)],
                    ),
                  ),
                  child: SvgPicture.asset(
                    MediaRes.message_panel_icon,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildChip({required String label}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xffE8E7F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xff1B237E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  final String value;
  final String label;

  const _TimeItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
