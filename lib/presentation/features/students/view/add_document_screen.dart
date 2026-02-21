import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/students/cubit/student_document_cubit.dart';
import 'package:wowcare/app/di/di.dart';

class AddStudentDocumentScreen extends StatefulWidget {
  const AddStudentDocumentScreen({
    super.key,
    required this.studentCode,
    this.isEdit = false,
    this.initialDocumentName,
    this.initialDocumentType,
    this.initialExpiryDate,
    this.initialFilePath,
  });
  static const String routeName = '/add-student-document-screen';

  final String studentCode;
  final bool isEdit;
  final String? initialDocumentName;
  final String? initialDocumentType;
  final DateTime? initialExpiryDate;
  final String? initialFilePath;

  @override
  _AddStudentDocumentScreenState createState() => _AddStudentDocumentScreenState();
}

class _AddStudentDocumentScreenState extends State<AddStudentDocumentScreen> {
  final TextEditingController _documentNameController = TextEditingController();
  String? _selectedDocumentType;
  DateTime? _selectedExpiryDate;
  String? _selectedFilePath;
  PlatformFile? _selectedFile;

  final List<String> _documentTypes = [
    'Educational',
    'Training',
    'Health',
    'Employment',
    'Resume',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Prefill when editing
    if (widget.isEdit) {
      if (widget.initialDocumentName != null) {
        _documentNameController.text = widget.initialDocumentName!.trim();
      }
      _selectedDocumentType = widget.initialDocumentType;
      _selectedExpiryDate = widget.initialExpiryDate;
      _selectedFilePath = widget.initialFilePath;
    }
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    super.dispose();
  }

  String _getMimeType(String extension) {
    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  void _addDocument() {
    if (_documentNameController.text.isEmpty) {
      _showWarningMessage('Document name is required');
      return;
    }

    if (_selectedDocumentType == null) {
      _showWarningMessage('Please select a document type');
      return;
    }

    if (_selectedExpiryDate == null) {
      _showWarningMessage('Please select an expiry date');
      return;
    }

    if (_selectedFile == null) {
      _showWarningMessage('Please upload a document');
      return;
    }

    if (widget.studentCode.isEmpty) {
      _showWarningMessage('Student code is required');
      return;
    }

    // storagePath: use file path when available (mobile), else file name
    final storagePath = _selectedFile!.path ?? _selectedFile!.name;
    final extension = _selectedFile!.extension?.toLowerCase() ?? '';
    final mimeType = _getMimeType(extension);
    final sizeBytes = _selectedFile!.size;

    context.read<StudentDocumentCubit>().addDocument(
          studentCode: widget.studentCode,
          name: _documentNameController.text.trim(),
          type: _selectedDocumentType!,
          expiryDate: DateFormat('yyyy-MM-dd').format(_selectedExpiryDate!),
          storagePath: storagePath,
          mimeType: mimeType,
          size: sizeBytes,
        );
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

  Future<void> _selectExpiryDate() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: _selectedExpiryDate,
        ),
      );
      
      if (result != null && result['date'] != null) {
        setState(() {
          _selectedExpiryDate = result['date'] as DateTime;
        });
      }
    } catch (e) {
      print('Error opening calendar dialog: $e');
    }
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          _selectedFile = file;
          _selectedFilePath = file.name;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      _showWarningMessage('Error selecting file. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocProvider<StudentDocumentCubit>(
      create: (_) => serviceLocator<StudentDocumentCubit>(),
      child: BlocListener<StudentDocumentCubit, StudentDocumentState>(
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message!,
              isSuccess: true,
            );
            Navigator.pop(context, true);
          } else if (state.isError && state.message != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message!,
              isError: true,
            );
          }
        },
        child: _buildForm(responsive, safeAreaBottom),
      ),
    );
  }

  Widget _buildForm(ResponsiveHelper responsive, double safeAreaBottom) {
    return StaffFormLayout(
      title: widget.isEdit ? "Edit Document" : "Add Document",
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildInputField(
              "Document name",
              "E.g. Report Card",
              _documentNameController,
            ),
            SizedBox(height: responsive.verticalSpacing),
            _buildCustomDropdown(),
            SizedBox(height: responsive.verticalSpacing),
            _buildDateField(),
            SizedBox(height: responsive.verticalSpacing),
            _buildFileUploadField(),
            const SizedBox(height: 12),
          ],
        ),
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
        child: BlocBuilder<StudentDocumentCubit, StudentDocumentState>(
          builder: (context, state) {
            final isSubmitting = state.isLoading;
            return Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: isSubmitting ? null : AppColors.buildPrimaryGradient(),
                color: isSubmitting ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
              ),
              child: TextButton(
                onPressed: isSubmitting ? null : _addDocument,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label, 
    String hint, 
    TextEditingController controller,
  ) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
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

  Widget _buildCustomDropdown() {
    return CustomDropdown(
      label: "Document Type *",
      hintText: "Select",
      items: _documentTypes,
      selectedItem: _selectedDocumentType,
      onSelect: (value) => setState(() => _selectedDocumentType = value),
    );
  }

  Widget _buildDateField() {
    final responsive = ResponsiveHelper(context);
    final labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              const TextSpan(text: 'Expiry Date'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: _selectExpiryDate,
          child: Container(
            constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0x66573353)),
              borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedExpiryDate != null 
                          ? DateFormat('MMM dd, yyyy').format(_selectedExpiryDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _selectedExpiryDate == null ? Colors.grey : Colors.black,
                        fontSize: responsive.inputFontSize,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    MediaRes.calender_icon,
                    height: responsive.isTablet ? 28.0 : 24.0,
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

  Widget _buildFileUploadField() {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.label.copyWith(
              fontSize: responsive.labelFontSize,
            ),
            children: [
              const TextSpan(text: 'Upload Document'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 4.0),
        GestureDetector(
          onTap: _selectFile,
          child: Container(
            height: responsive.inputFieldHeight,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.isTablet ? 20.0 : 16.0,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x66573353)),
              borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedFilePath ?? 'Choose a File',
                    style: TextStyle(
                      color: _selectedFilePath == null ? Colors.grey : Colors.black,
                      fontSize: responsive.inputFontSize,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                SvgPicture.asset(
                  MediaRes.uploadIcon,
                  height: responsive.isTablet ? 28.0 : 24.0,
                  colorFilter: const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

