import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/src/core/util/typedefs.dart' show DataMap;

import '../../res/colors.dart';

enum FieldType { text, dropdown, datePicker, fileUpload }

class DynamicFormField {
  final String label;
  final FieldType type;
  final List<String>? dropdownOptions;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;
  final Key? key;
  final bool isRequired; // Added required field flag

  DynamicFormField({
    this.key,
    required this.label,
    required this.type,
    this.dropdownOptions,
    this.controller,
    this.validator,
    this.onChanged,
    this.isRequired = false, // Default to false
  });

  DynamicFormField copyWith({
    Key? key,
    String? label,
    FieldType? type,
    List<String>? dropdownOptions,
    TextEditingController? controller,
    String? Function(String?)? validator,
    Function(String?)? onChanged,
    bool? isRequired,
  }) {
    return DynamicFormField(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      dropdownOptions: dropdownOptions ?? this.dropdownOptions,
      controller: controller ?? this.controller,
      validator: validator ?? this.validator,
      onChanged: onChanged ?? this.onChanged,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

class DynamicModalBottomSheet extends StatefulWidget {
  final String title;
  final List<DynamicFormField> fields;
  final void Function(DataMap) onSubmit;

  const DynamicModalBottomSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
  });

  static void show(
    BuildContext context, {
    required String title,
    required List<DynamicFormField> fields,
    required void Function(DataMap) onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DynamicModalBottomSheet(
        title: title,
        fields: fields,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  _DynamicModalBottomSheetState createState() =>
      _DynamicModalBottomSheetState();
}

class _DynamicModalBottomSheetState extends State<DynamicModalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  DataMap formValues = {};
  DateTime? selectedDate;
  File? selectedFile;
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(5),
    borderSide: const BorderSide(color: Colors.grey),
  );

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      if (field.controller != null) {
        formValues[field.label] = field.controller!.text;
      }
    }
  }

  Future<void> _selectDate(BuildContext context, DynamicFormField field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        field.controller?.text = DateFormat('yyyy-MM-dd').format(picked);
        formValues[field.label] = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          selectedFile = File(result.files.first.path!);
          formValues['File'] = result.files.first.path; // Update formValues
        });
        debugPrint('File picked: ${result.files.first.path}');

        // Call the onChanged callback to update the state
        for (var field in widget.fields) {
          if (field.type == FieldType.fileUpload && field.onChanged != null) {
            field.onChanged!(result.files.first.path); // Pass the file path
          }
        }
      } else {
        debugPrint('No file selected');
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  // Helper method to create field label with required indicator
  Widget _createLabel(DynamicFormField field) {
    return Text(
      '${field.label}${field.isRequired ? ' *' : ''}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  // Default validator that includes required field check
  String? _defaultValidator(String? value, DynamicFormField field) {
    if (field.isRequired && (value == null || value.isEmpty)) {
      return '${field.label} is required';
    }
    return field.validator?.call(value);
  }

  Widget _buildFormField(DynamicFormField field) {
    switch (field.type) {
      case FieldType.text:
        return TextFormField(
          controller: field.controller,
          decoration: InputDecoration(
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.blue),
            ),
            label: _createLabel(field), // Only using label, removed labelText
          ),
          validator: (value) => _defaultValidator(value, field),
          onChanged: (value) => formValues[field.label] = value,
        );

      case FieldType.dropdown:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.blue),
            ),
            label: _createLabel(field), // Only using label, removed labelText
          ),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(
                'Select ${field.label}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ...?field.dropdownOptions?.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }),
          ],
          value: formValues[field.label] ?? '',
          onChanged: (value) {
            setState(() {
              formValues[field.label] = value;
              if (field.onChanged != null) {
                field.onChanged!(value);
              }
            });
          },
          validator: (value) => _defaultValidator(value, field),
        );

      case FieldType.datePicker:
        return GestureDetector(
          onTap: () => _selectDate(context, field),
          child: AbsorbPointer(
            child: TextFormField(
              controller: field.controller,
              decoration: InputDecoration(
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
                label: _createLabel(
                  field,
                ), // Only using label, removed labelText
              ),
              validator: (value) => _defaultValidator(value, field),
            ),
          ),
        );

      case FieldType.fileUpload:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _createLabel(field),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(right: 10),
                      color: Colors.grey.shade300,
                      child: const Text(
                        'Choose File',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        selectedFile?.path.split('/').last ?? 'No File Chosen',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (field.isRequired && selectedFile == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${field.label} is required',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...widget.fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildFormField(field),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.themeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSubmit({...formValues, 'File': selectedFile});
                        Navigator.of(context).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
