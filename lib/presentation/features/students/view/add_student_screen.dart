import 'package:wowcare/core/util/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'dart:async';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/core/util/core_utils.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({
    super.key,
    this.isEdit = false,
    this.initialFirstName,
    this.initialLastName,
    this.initialClassroom,
    this.initialStatus,
  });
  static const String routeName = '/add-student-screen';

  final bool isEdit;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialClassroom;
  final String? initialStatus;

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? _selectedClassroom;
  final List<String> _classrooms = [
    'Nursery A',
    'Nursery B',
    'Playgroup',
    'Daycare',
  ]; // Mock data
  String? _ClassroomError;
  //bool _isLoading = false;
  bool _isSubmitting = false;

  String? _selectedStatus;
  //final List<String> _statuses = ['Active', 'Inactive'];

  OverlayEntry? _overlayEntry;
  String? _warningMessage;
  Timer? _warningTimer;

  @override
  void initState() {
    super.initState();
    // Prefill when editing
    if (widget.isEdit) {
      if (widget.initialFirstName != null) {
        _firstNameController.text = widget.initialFirstName!.trim();
      }
      if (widget.initialLastName != null) {
        _lastNameController.text = widget.initialLastName!.trim();
      }
      _selectedClassroom = widget.initialClassroom;
      //_selectedStatus = widget.initialStatus;
    }
  }

  @override
  void dispose() {
    _removeDropdownOverlay();
    _warningTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _addStudent() {
    _trimAllInputs();
    if (_firstNameController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First name is required',
        isError: true,
      );
      return;
    }
    if (_lastNameController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last name is required',
        isError: true,
      );
      return;
    }

    if (_selectedClassroom == null) {
      setState(() {
        _ClassroomError = 'Please select a classroom';
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a Classroom',
        isError: true,
      );
      return;
    }

    if (_selectedStatus == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a status',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Mock API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSubmitting = false;
      });
      final studentName = _composeStudentName();
      bool sameName = false;
      if (('${widget.initialFirstName} ${widget.initialLastName}')
              .toLowerCase() ==
          studentName.toLowerCase()) {
        sameName = true;
      }
      // Debug
      AppLogger.d(
        '[AddStudent] Returning to previous screen with studentName="$studentName"',
      );
      CoreUtils.showTopSnackBar(
        duration: sameName ? Duration(seconds: 2) : Duration(seconds: 4),
        context: context,
        message: widget.isEdit
            ? (sameName
                  ? 'The details of the student ${studentName.isNotEmpty ? ' $studentName ' : ' '} are edited successfully'
                  : 'The details of the student ${studentName.isNotEmpty ? ' $studentName ' : ' '} previously known as ${widget.initialFirstName} ${widget.initialLastName} are edited successfully')
            : 'A new student${studentName.isNotEmpty ? ' $studentName ' : ' '}is added successfully',
        isSuccess: true,
      );
      final result = {'showPostAddPrompt': true, 'studentName': studentName};
      AppLogger.d('[AddStudent] Navigator.pop result: ' + result.toString());
      Navigator.pop(context, result);
    });
  }

  String _composeStudentName() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final name = [first, last].where((p) => p.isNotEmpty).join(' ');
    return name;
  }

  void _trimAllInputs() {
    _firstNameController.text = _firstNameController.text.trim();
    _lastNameController.text = _lastNameController.text.trim();
  }

  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        _removeDropdownOverlay();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(hasBackButton: true),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isEdit ? "Edit Student" : "Add Student",
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                Expanded(
                  child: Container(
                    width: responsive.containerWidth,
                    margin: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalSpacing,
                    ),
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_warningMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _warningMessage!,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _warningMessage = null;
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              SizedBox(height: responsive.verticalSpacing),
                              _buildRowInputs(
                                context,
                                "First Name",
                                "Last Name",
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              // Classroom
                              CustomDropdown(
                                label: "Classroom",
                                hintText: 'Select',
                                items: _classrooms,
                                selectedItem: _selectedClassroom,
                                labelStyle: TextStyle(
                                  fontSize: responsive.labelFontSize,
                                  fontFamily: "Manrope",
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xff573353),
                                ),
                                showAsterisk: true,
                                labelBottomSpacing: responsive.isTablet
                                    ? 8.0
                                    : 6.0,
                                onSelect: (val) => setState(
                                  () => _selectedClassroom =
                                      val ?? _selectedClassroom,
                                ),
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              CustomDropdown(
                                label: "Status",
                                hintText: 'Select',
                                items: const ['Active', 'Upcoming', 'Inactive'],
                                selectedItem: _selectedStatus,
                                labelStyle: TextStyle(
                                  fontSize: responsive.labelFontSize,
                                  fontFamily: "Manrope",
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xff573353),
                                ),
                                showAsterisk: true,
                                labelBottomSpacing: responsive.isTablet
                                    ? 8.0
                                    : 6.0,
                                onSelect: (val) => setState(
                                  () =>
                                      _selectedStatus = val ?? _selectedStatus,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            bottom: safeAreaBottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -4),
                blurRadius: 16,
              ),
            ],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
              topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
            ),
          ),
          child: Container(
            height: responsive.buttonHeight,
            decoration: BoxDecoration(
              gradient: _isSubmitting ? null : AppColors.buildPrimaryGradient(),
              color: _isSubmitting ? Colors.grey[300] : null,
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 16.0 : 8.0,
              ),
            ),
            child: TextButton(
              onPressed: _isSubmitting ? null : _addStudent,
              child: Text(
                widget.isEdit ? 'Save' : 'Add',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.buttonFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowInputs(BuildContext context, String label1, String label2) {
    final responsive = ResponsiveHelper(context);
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            label1,
            "E.g. John",
            _firstNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s]")),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
        SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
        Expanded(
          child: _buildInputField(
            label2,
            "E.g. Smith",
            _lastNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s]")),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600, // typing weight
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove trailing spaces
    text = text.replaceFirst(
      RegExp(r"\s+"),
      ' ',
    ); // collapse multiple spaces inside
    text = text.replaceAll(RegExp(r"\s{2,}"), ' ');
    text = text.replaceAll(RegExp(r"\s+\z"), '');

    if (text.isEmpty) {
      return newValue.copyWith(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Enforce first letter uppercase, remaining lowercase
    final firstChar = text[0].toUpperCase();
    final rest = text.length > 1 ? text.substring(1).toLowerCase() : '';
    final formatted = firstChar + rest;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TrimFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trimmed = newValue.text.trimLeft();
    // Preserve caret at end for simplicity
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
}
