import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';

class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  List<String> items = const [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CustomMultiSelectDropdown(
          hintText: 'Select guardian',
          items: items,
          selectedItems: const [],
          onChanged: (_) {},
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'an already-open overlay picks up items that arrive after it was opened '
    '(e.g. an async fetch resolving while the dropdown is already open) '
    'instead of freezing on the empty snapshot it was created with',
    (tester) async {
      await tester.pumpWidget(const _Harness());

      // Open the dropdown BEFORE the data arrives - matches a user tapping
      // the field immediately after the screen loads, before the guardian
      // fetch resolves.
      await tester.tap(find.text('Select guardian'));
      await tester.pumpAndSettle();
      expect(find.text('No matches found'), findsOneWidget);

      // The fetch "resolves" - items update while the dropdown is still
      // open. Set state directly (rather than tapping a widget) since the
      // open overlay's full-screen dismiss barrier would otherwise swallow
      // any tap meant for something behind it.
      tester.state<_HarnessState>(find.byType(_Harness)).setState(() {
        tester.state<_HarnessState>(find.byType(_Harness)).items = const [
          'Billing Parent',
          'Silling Parent',
        ];
      });
      await tester.pumpAndSettle();

      // The already-open overlay must reflect the new items, not stay frozen.
      expect(find.text('No matches found'), findsNothing);
      expect(find.text('Billing Parent'), findsOneWidget);
      expect(find.text('Silling Parent'), findsOneWidget);
    },
  );
}
