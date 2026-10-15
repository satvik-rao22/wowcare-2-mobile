import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/app_image/app_image.dart';
import 'package:wowcare/shared/common/widgets/attendance_status_dot.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('no photo: shows the initials', (tester) async {
    await tester.pumpWidget(_host(const ProfileAvatar(name: 'Sara Malik')));

    expect(find.text('SM'), findsOneWidget);
    expect(find.byType(AppImage), findsNothing);
  });

  testWidgets('blank name: shows a person icon', (tester) async {
    await tester.pumpWidget(_host(const ProfileAvatar(name: '')));

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('a ready URL is drawn by AppImage', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProfileAvatar(
          name: 'Sara Malik',
          imageUrl: 'https://example.com/sara.jpg',
        ),
      ),
    );

    final image = tester.widget<AppImage>(find.byType(AppImage));
    expect(image.source, 'https://example.com/sara.jpg');
    expect(image.shape, BoxShape.circle);
  });

  testWidgets('a given status colour shows the dot', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProfileAvatar(
          name: 'Sara Malik',
          statusDot: AttendanceStatusDot(color: Colors.green, tooltip: 'In'),
        ),
      ),
    );

    expect(find.byTooltip('In'), findsOneWidget);
  });

  testWidgets('UPCOMING wins over a given colour', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProfileAvatar(
          name: 'Sara Malik',
          statusDot: AttendanceStatusDot(
            staffCode: 'STF_1',
            profileStatus: 'upcoming',
            color: Colors.green,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Upcoming staff'), findsOneWidget);
  });
}
