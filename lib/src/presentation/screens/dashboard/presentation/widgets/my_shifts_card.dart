import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const double cellHeightRow = 40;

class MyShiftsCard extends StatefulWidget {
  const MyShiftsCard({super.key});

  @override
  State<MyShiftsCard> createState() => MyShiftsCardState();
}

class MyShiftsCardState extends State<MyShiftsCard> {
  DateTime _selectedShiftDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Shifts',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mock staff details
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    "U",
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Uttam Kumar", // mock staff name
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Teacher", // mock designation
                        style: TextStyle(color: Colors.blue),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Room A", // mock primary room
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Weekly summary (static tiles)
            const ShiftHoursTile(
              bgColor: Color.fromRGBO(255, 250, 234, 1.0),
              label: 'Available Hours',
              hours: '40',
              icon: Icons.access_time,
            ),
            const SizedBox(height: 16),
            const ShiftHoursTile(
              bgColor: Color.fromRGBO(234, 255, 250, 1.0),
              label: 'Scheduled Hours',
              hours: '32',
              icon: Icons.schedule,
            ),
            const SizedBox(height: 16),
            const ShiftHoursTile(
              bgColor: Color.fromRGBO(22, 40, 49, 0.05),
              label: 'Unscheduled Hours',
              hours: '8',
              icon: Icons.pending_actions,
            ),

            const SizedBox(height: 20),

            // Mock calendar
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                border: const Border(
                  bottom: BorderSide(width: 1, color: Colors.grey),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        'Time',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Text(
                        DateFormat('EEE, MMM d').format(_selectedShiftDate),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Static daily shifts
            const ShiftCalendar(),
          ],
        ),
      ),
    );
  }
}

class ShiftHoursTile extends StatelessWidget {
  const ShiftHoursTile({
    super.key,
    required this.bgColor,
    required this.label,
    required this.hours,
    required this.icon,
  });

  final Color bgColor;
  final String label;
  final String hours;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            hours,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftCalendar extends StatelessWidget {
  const ShiftCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    // Static example shifts
    final shifts = [
      {"room": "Room A", "start": "09:00 AM", "end": "11:00 AM"},
      {"room": "Room B", "start": "11:30 AM", "end": "01:00 PM"},
      {
        "room": "Break",
        "start": "01:00 PM",
        "end": "02:00 PM",
        "isBreak": true,
      },
      {"room": "Room C", "start": "02:00 PM", "end": "04:00 PM"},
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      height: cellHeightRow * 8,
      child: Column(
        children: shifts.map((shift) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: shift["isBreak"] == true
                  ? const Color.fromRGBO(254, 241, 199, 1.0)
                  : const Color.fromRGBO(234, 244, 255, 1.0),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                shift["isBreak"] == true
                    ? "🍔 Break (${shift['start']} - ${shift['end']})"
                    : "${shift['room']} (${shift['start']} - ${shift['end']})",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
