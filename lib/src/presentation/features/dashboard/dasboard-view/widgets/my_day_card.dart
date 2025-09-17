import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../../core/res/colors.dart';

class MyDayCard extends StatefulWidget {
  const MyDayCard({super.key});

  @override
  State<MyDayCard> createState() => _MyDayCardState();
}

class _MyDayCardState extends State<MyDayCard> {
  Timer? _timer;
  Duration _duration = const Duration(hours: 2, minutes: 30, seconds: 0);
  bool _hasShifts = true;
  bool _isReminder = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_duration.inSeconds > 0) {
          _duration -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Timer Display
            ShiftTimer(duration: _duration, hasShifts: _hasShifts),

            const SizedBox(height: 16),

            // Reminder Toggle (static)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isReminder ? "Reminders On" : "Reminders Off",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Switch(
                  value: _isReminder,
                  activeColor: AppColors.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _isReminder = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sign In / Out button (static)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSignedIn
                    ? Colors.red
                    : AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                setState(() {
                  _isSignedIn = !_isSignedIn;
                });
              },
              child: Text(
                _isSignedIn ? "Sign Out" : "Sign In",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Communication row (static)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.chat, color: AppColors.primaryColor, size: 32),
                Icon(Icons.email, color: AppColors.primaryColor, size: 32),
                Icon(Icons.call, color: AppColors.primaryColor, size: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShiftTimer extends StatelessWidget {
  final Duration duration;
  final bool hasShifts;
  const ShiftTimer({
    super.key,
    required this.duration,
    required this.hasShifts,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasShifts) {
      return const Text("No upcoming shifts today");
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return Text(
      "Next shift in: ${hours}h ${minutes}m ${seconds}s",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
