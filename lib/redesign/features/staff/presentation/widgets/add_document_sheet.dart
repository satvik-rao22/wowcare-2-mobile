import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

/// What the sheet resolves to: a name and a type for the file being added.
@immutable
class NewStaffDocument {
  const NewStaffDocument({required this.name, required this.type});

  final String name;
  final String type;
}

/// Added. 6c draws the "Add a document" key and stops there, so this is the
/// smallest step it can lead to: what the file is called and what kind of
/// thing it is.
///
/// Picking the file itself is the platform's job and is not drawn in any
/// frame; this is the record the upload attaches to.
class AddDocumentSheet extends StatefulWidget {
  const AddDocumentSheet({super.key});

  static Future<NewStaffDocument?> show(BuildContext context) =>
      showAppSheet<NewStaffDocument>(
        context,
        builder: (_) => const AddDocumentSheet(),
      );

  @override
  State<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<AddDocumentSheet> {
  final TextEditingController _name = TextEditingController();
  String? _type;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _isReady => _name.text.trim().isNotEmpty && _type != null;

  Future<void> _pickType() async {
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StaffStrings.pickDocumentType,
      options: <SelectOption<String>>[
        for (final type in StaffStrings.documentTypes)
          SelectOption<String>(value: type, label: type),
      ],
      selected: _type,
    );
    if (picked != null && mounted) setState(() => _type = picked);
  }

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: StaffStrings.addDocument,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.wizardFieldGap,
      children: <Widget>[
        AppTextField(
          label: StaffStrings.documentName,
          isRequired: true,
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        DropdownField(
          label: StaffStrings.documentType,
          isRequired: true,
          value: _type,
          placeholder: StaffStrings.pickDocumentType,
          onTap: () => unawaited(_pickType()),
        ),
      ],
    ),
    footer: <Widget>[
      PrimaryKey(
        label: StaffStrings.addDocumentKey,
        enabled: _isReady,
        padding: StaffSizes.sheetKeyPad,
        onTap: () => Navigator.of(
          context,
        ).pop(NewStaffDocument(name: _name.text.trim(), type: _type!)),
      ),
    ],
  );
}
