import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Dummy static Enrollment Card (UI-only)
class EnrollmentCard extends StatelessWidget {
  const EnrollmentCard({required this.isDashboard, super.key});

  final bool isDashboard;

  @override
  Widget build(BuildContext context) {
    // Dummy static data
    const int totalStudents = 120;
    const int activeStudents = 90;
    const int upcomingStudents = 30;

    const int expectedStudents = 100;
    const int presentStudents = 80;
    const int absentStudents = 20;

    const int expectedStaff = 20;
    const int presentStaff = 18;
    const int absentStaff = 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Classroom summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StatBox(value: "12", label: "Total\nClassrooms"),
              _StatBox(value: "300", label: "Total\nCapacity"),
              _StatBox(value: "85%", label: "Full time\nEquivalent"),
            ],
          ),

          if (isDashboard) Divider(color: Colors.grey.shade300),
          if (isDashboard) const SizedBox(height: 12),

          // Enrolled Students
          if (isDashboard)
            _EnrolledStudentsSection(
              totalStudents: totalStudents,
              activeStudents: activeStudents,
              upcomingStudents: upcomingStudents,
            ),

          if (isDashboard) const SizedBox(height: 20),

          // Expected students & staff
          if (isDashboard)
            Row(
              children: const [
                Expanded(
                  child: _ExpectedSection(
                    value: "100",
                    label: "Expected Students",
                    presentLabel: "Present (80)",
                    absentLabel: "Absent (20)",
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _ExpectedSection(
                    value: "20",
                    label: "Expected Staff",
                    presentLabel: "Present (18)",
                    absentLabel: "Absent (2)",
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// --- Small reusable Widgets ---

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrolledStudentsSection extends StatelessWidget {
  final int totalStudents;
  final int activeStudents;
  final int upcomingStudents;

  const _EnrolledStudentsSection({
    required this.totalStudents,
    required this.activeStudents,
    required this.upcomingStudents,
  });

  @override
  Widget build(BuildContext context) {
    final activeRatio = totalStudents > 0
        ? (activeStudents / totalStudents)
        : 0.0;
    final upcomingRatio = totalStudents > 0
        ? (upcomingStudents / totalStudents)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + total count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enrolled Students',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$totalStudents',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress bar
        Row(
          children: [
            Expanded(
              flex: (activeRatio * 100).round(),
              child: Container(
                height: 24,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                  color: Colors.lightBlue,
                ),
              ),
            ),
            Expanded(
              flex: (upcomingRatio * 100).round(),
              child: Container(
                height: 24,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(10),
                  ),
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Legend
        Row(
          children: [
            _StatusIndicator(
              color: Colors.lightBlue,
              label: "Active ($activeStudents)",
            ),
            const SizedBox(width: 16),
            _StatusIndicator(
              color: Colors.amber,
              label: "Upcoming ($upcomingStudents)",
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpectedSection extends StatelessWidget {
  final String value;
  final String label;
  final String presentLabel;
  final String absentLabel;

  const _ExpectedSection({
    required this.value,
    required this.label,
    required this.presentLabel,
    required this.absentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatBox(value: value, label: label),
        const SizedBox(height: 8),
        _StatusIndicator(color: Colors.green, label: presentLabel),
        const SizedBox(height: 8),
        _StatusIndicator(color: Colors.red, label: absentLabel),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusIndicator({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
