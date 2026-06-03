import 'package:flutter/material.dart';

/// Kiosk dashboard screen - full-screen tablet UI for school entrance kiosk.
/// Displays QR code and PIN entry pad for attendance marking.
class KioskDashboardScreen extends StatelessWidget {
  const KioskDashboardScreen({super.key});

  static const String routeName = '/kiosk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kiosk Dashboard',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'QR Code Display Area',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: const Center(
                child: Text('QR Code Placeholder'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PIN Entry Pad',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
