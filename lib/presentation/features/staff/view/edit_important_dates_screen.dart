import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class EditImportantDatesScreen extends StatefulWidget {
  const EditImportantDatesScreen({
    super.key,
    this.initialHireDate,
    this.initialCdaExaminationDate,
    this.initialFirstAidCprExpirationDate,
    this.initialBackgroundRecordCheckExpirationDate,
  });
  static const String routeName = '/edit-important-dates-screen';

  final DateTime? initialHireDate;
  final DateTime? initialCdaExaminationDate;
  final DateTime? initialFirstAidCprExpirationDate;
  final DateTime? initialBackgroundRecordCheckExpirationDate;

  @override
  _EditImportantDatesScreenState createState() => _EditImportantDatesScreenState();
}

class _EditImportantDatesScreenState extends State<EditImportantDatesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _selectedHireDate;
  DateTime? _selectedCdaExaminationDate;
  DateTime? _selectedFirstAidCprExpirationDate;
  DateTime? _selectedBackgroundRecordCheckExpirationDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill when editing
    _selectedHireDate = widget.initialHireDate;
    _selectedCdaExaminationDate = widget.initialCdaExaminationDate;
    _selectedFirstAidCprExpirationDate = widget.initialFirstAidCprExpirationDate;
    _selectedBackgroundRecordCheckExpirationDate = widget.initialBackgroundRecordCheckExpirationDate;
  }

  void _saveImportantDates() {
    if (_selectedHireDate == null) {
      _showWarningMessage('Hire Date is required');
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
      Navigator.pop(context);
    });
  }

  void _showWarningMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange.shade50,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.shade100),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _selectDate(String fieldName) async {
    try {
      DateTime? currentDate;
      switch (fieldName) {
        case 'hire':
          currentDate = _selectedHireDate;
          break;
        case 'cda':
          currentDate = _selectedCdaExaminationDate;
          break;
        case 'firstAid':
          currentDate = _selectedFirstAidCprExpirationDate;
          break;
        case 'background':
          currentDate = _selectedBackgroundRecordCheckExpirationDate;
          break;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: currentDate,
        ),
      );
      
      if (result != null && result['date'] != null) {
        setState(() {
          switch (fieldName) {
            case 'hire':
              _selectedHireDate = result['date'] as DateTime;
              break;
            case 'cda':
              _selectedCdaExaminationDate = result['date'] as DateTime;
              break;
            case 'firstAid':
              _selectedFirstAidCprExpirationDate = result['date'] as DateTime;
              break;
            case 'background':
              _selectedBackgroundRecordCheckExpirationDate = result['date'] as DateTime;
              break;
          }
        });
      }
    } catch (e) {
      print('Error opening calendar dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return StaffFormLayout(
      title: "Edit Important Dates",
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDateField(
            "Hire Date",
            _selectedHireDate,
            'hire',
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDateField(
            "CDA Examination Date",
            _selectedCdaExaminationDate,
            'cda',
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDateField(
            "First Aid/CPR Expiration Date",
            _selectedFirstAidCprExpirationDate,
            'firstAid',
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDateField(
            "Background Record Check Expiration date",
            _selectedBackgroundRecordCheckExpirationDate,
            'background',
          ),
          const SizedBox(height: 12),
        ],
      ),
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom, left: 16, right: 16, top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
            borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
          ),
          child: TextButton(
            onPressed: _isSubmitting ? null : _saveImportantDates,
            child: Text(
              'Save',
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
    );
  }

  Widget _buildDateField(
    String label, 
    DateTime? selectedDate,
    String fieldName,
  ) {
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
        // Label with required asterisk - keeping original styling
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              if (fieldName == 'hire') const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        // Date field container with CustomDropdown styling
        GestureDetector(
          onTap: () => _selectDate(fieldName),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      selectedDate != null 
                          ? DateFormat('MMM dd, yyyy').format(selectedDate)
                          : 'Select Date',
                      style: TextStyle(
                        color: selectedDate == null 
                            ? AppColors.primaryColor.withOpacity(0.6)
                            : AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    MediaRes.calender_icon,
                    height: 20.0,
                    colorFilter: const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
