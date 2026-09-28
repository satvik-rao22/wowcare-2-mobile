import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/presentation/features/app_update/app_update_strings.dart';
import 'package:wowcare/presentation/features/app_update/view_model/app_update_cubit.dart';
import 'package:wowcare/presentation/features/app_update/widgets/app_update_gate.dart';
import 'package:wowcare/presentation/features/app_update/widgets/optional_update_banner.dart';
import 'package:wowcare/presentation/features/app_update/widgets/pulsing_logo_mark.dart';

import 'app_update_test_support.dart';

/// The app under the gate: one text field, so the tests can see whether the
/// overlay really takes focus away from it.
Widget _app(AppUpdateCubit cubit, {bool reduceMotion = false}) {
  return BlocProvider<AppUpdateCubit>.value(
    value: cubit,
    child: MaterialApp(
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: AppUpdateGate(child: child!),
      ),
      home: const Scaffold(
        body: Column(
          children: <Widget>[
            OptionalUpdateBanner(),
            TextField(autofocus: true),
          ],
        ),
      ),
    ),
  );
}

Future<AppUpdateCubit> _checked(FakeAppUpdateRepository repo) async {
  final AppUpdateCubit cubit = cubitOver(repo);
  await cubit.check();
  return cubit;
}

void main() {
  testWidgets('the logo mark asset parses', (WidgetTester tester) async {
    final PictureInfo? info = await tester.runAsync(
      () => vg.loadPicture(const SvgAssetLoader(MediaRes.logoMark), null),
    );
    expect(info, isNotNull);
    expect(info!.size.width, greaterThan(0));
    info.picture.dispose();
  });

  testWidgets('up to date: no banner, no overlay', (WidgetTester tester) async {
    final AppUpdateCubit cubit = await _checked(FakeAppUpdateRepository());
    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.byType(PulsingLogoMark), findsNothing);
    expect(find.text(AppUpdateStrings.notNow), findsNothing);
  });

  for (final (String name, Size size) in <(String, Size)>[
    ('phone', Size(390, 844)),
    ('tablet', Size(1024, 768)),
  ]) {
    testWidgets('optional on a $name: shows, and Not now puts it away', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
        cachedPolicy: optionalFor25,
      );
      final AppUpdateCubit cubit = await _checked(repo);
      await tester.pumpWidget(_app(cubit));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text(AppUpdateStrings.optionalTitle('2.3.0')),
        findsOneWidget,
      );
      expect(find.text(AppUpdateStrings.youAreOn('2.2.21')), findsOneWidget);
      expect(find.byType(PulsingLogoMark), findsOneWidget);

      await tester.tap(find.text(AppUpdateStrings.notNow));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PulsingLogoMark), findsNothing);
      expect(repo.dismissedBuilds, <int>[26]);
    });
  }

  testWidgets('optional: the cross dismisses too', (WidgetTester tester) async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
      cachedPolicy: optionalFor25,
    );
    final AppUpdateCubit cubit = await _checked(repo);
    await tester.pumpWidget(_app(cubit));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.bySemanticsLabel(AppUpdateStrings.dismiss));
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.dismissedBuilds, <int>[26]);
  });

  testWidgets('required: the overlay covers the app and takes its focus', (
    WidgetTester tester,
  ) async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
      cachedPolicy: requiredFor25,
    );
    final AppUpdateCubit cubit = await _checked(repo);
    await tester.pumpWidget(_app(cubit));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppUpdateStrings.requiredTitle('3.0.0')), findsOneWidget);
    expect(find.text(AppUpdateStrings.notNow), findsNothing);
    expect(find.bySemanticsLabel(AppUpdateStrings.dismiss), findsNothing);
    final EditableText field = tester.widget(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isFalse);

    await tester.tap(find.text(AppUpdateStrings.getFrom(repo.store, '3.0.0')));
    await tester.pump();
    expect(repo.openedUrls, hasLength(1));
  });

  testWidgets('the mark animates, and stops under reduce motion', (
    WidgetTester tester,
  ) async {
    final AppUpdateCubit cubit = await _checked(
      FakeAppUpdateRepository(cachedPolicy: requiredFor25),
    );

    await tester.pumpWidget(_app(cubit));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.hasRunningAnimations, isTrue);
    expect(
      find.descendant(
        of: find.byType(PulsingLogoMark),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(_app(cubit, reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      find.descendant(
        of: find.byType(PulsingLogoMark),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });
}
