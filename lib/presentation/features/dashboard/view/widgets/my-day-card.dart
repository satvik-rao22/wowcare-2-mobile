import 'package:flutter/material.dart';

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
        color: const Color(0xffF8F8F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE6E6E6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Day',
                      style: TextStyle(
                        color: Color(0xff5A3458),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    InkWell(
                      onTap: () {
                        setState(() {
                          _minimized = !_minimized;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: GradientToggleButton(
                        minimized: _minimized,
                        onTap: () {
                          setState(() {
                            _minimized = !_minimized;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                if (!_minimized) ...[
                  const SizedBox(height: 28),

                  /// STATUS
                  const Text(
                    'Your shift starts in',
                    style: TextStyle(
                      color: Color(0xff5A3458),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// TIMER
                  const Text(
                    '00:15:28',
                    style: TextStyle(
                      color: Color(0xff5A3458),
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// REMINDER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.notifications,
                        color: Color(0xff7B7DFF),
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Send Reminder set 30 min before',
                        style: TextStyle(
                          color: Color(0xff7B7DFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  /// WORK TIME
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8E6F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Work Time : 07:00 AM - 05:30 PM',
                      style: TextStyle(
                        color: Color(0xff24338F),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// BREAK TIME
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8E6F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Break Time : 12:00 PM - 12:30 PM',
                      style: TextStyle(
                        color: Color(0xff24338F),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// PIN + QR
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
                          'Your Sign-In Pin: 1548',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 18),

                      const Icon(
                        Icons.qr_code_scanner,
                        size: 56,
                        color: Color(0xff8D86FF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),

                  /// BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xff6E7BFF)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Transfer',
                              style: TextStyle(
                                color: Color(0xff6E7BFF),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff5978F7), Color(0xff9B84FF)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Sign-Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          /// BOTTOM USER SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xffEEF0F7),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=32',
                  ),
                ),

                const SizedBox(width: 16),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amber James',
                        style: TextStyle(
                          color: Color(0xff5A3458),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Director',
                        style: TextStyle(
                          color: Color(0xff8D8D99),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff5978F7), Color(0xff9B84FF)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
