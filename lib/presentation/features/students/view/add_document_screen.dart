import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
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
    this.initialMimeType,
    this.initialFileSizeKb,
    this.initialDocumentNotes,
    this.documentUuid,
  });
  static const String routeName = '/add-student-document-screen';

  final String studentCode;
  final bool isEdit;
  final String? initialDocumentName;
  final String? initialDocumentType;
  final DateTime? initialExpiryDate;
  final String? initialFilePath;
  final String? initialMimeType;
  final int? initialFileSizeKb;
  final String? initialDocumentNotes;
  final String? documentUuid;

  @override
  _AddStudentDocumentScreenState createState() => _AddStudentDocumentScreenState();
}

class _AddStudentDocumentScreenState extends State<AddStudentDocumentScreen> {
  final TextEditingController _documentNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedDocumentType;
  DateTime? _selectedExpiryDate;
  String? _selectedFilePath;
  PlatformFile? _selectedFile;
  static const int _documentNameMaxLength = 100;
  static const int _notesMaxLength = 500;

  final List<String> _documentTypes = [
    'Birth Certificate',
    'Health Forms',
    'Registration Forms',
    'Special Program Forms',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      if (widget.initialDocumentName != null) {
        _documentNameController.text = widget.initialDocumentName!.trim();
      }
      _selectedDocumentType = widget.initialDocumentType;
      _selectedExpiryDate = widget.initialExpiryDate;
      _selectedFilePath = widget.initialFilePath;
      if (widget.initialDocumentNotes != null) {
        _notesController.text = widget.initialDocumentNotes!.trim();
      }
    }
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getMimeType(String extension) {
    const mimeTypes = {
      'pdf': 'application/pdf',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'heic': 'image/heic',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  void _addDocument(BuildContext context) {
    final name = _documentNameController.text.trim();
    if (name.isEmpty) {
      _showWarningMessage('Document name is required');
      return;
    }
    if (name.length > _documentNameMaxLength) {
      _showWarningMessage('Document name must be at most $_documentNameMaxLength characters');
      return;
    }

    if (_selectedDocumentType == null) {
      _showWarningMessage('Please select a document type');
      return;
    }

    if (_notesController.text.length > _notesMaxLength) {
      _showWarningMessage('Notes must be at most $_notesMaxLength characters');
      return;
    }

    if (!widget.isEdit && _selectedFile == null) {
      _showWarningMessage('Please upload a document');
      return;
    }

    if (widget.studentCode.isEmpty) {
      _showWarningMessage('Student code is required');
      return;
    }

    String storagePath;
    int sizeBytes;
    String mimeType;

    if (_selectedFile != null) {
      storagePath = _selectedFile!.path ?? _selectedFile!.name;
      sizeBytes = _selectedFile!.size;
      final extension = _selectedFile!.extension?.toLowerCase() ?? '';
      mimeType = _getMimeType(extension);
    } else if (widget.isEdit && widget.initialFilePath != null) {
      storagePath = widget.initialFilePath!;
      sizeBytes = (widget.initialFileSizeKb ?? 0) * 1024;
      mimeType = widget.initialMimeType ?? 'application/pdf';
    } else {
      _showWarningMessage('Please upload a document');
      return;
    }

    final cubit = context.read<StudentDocumentCubit>();

    final documentType = _selectedDocumentType!.toUpperCase().replaceAll(' ', '_');

    final payload = (
      studentCode: widget.studentCode,
      name: name,
      type: documentType,
      expiryDate: _selectedExpiryDate != null 
          ? DateFormat('yyyy-MM-dd').format(_selectedExpiryDate!)
          : '',
      storagePath: storagePath,
      mimeType: mimeType,
      size: sizeBytes,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (widget.isEdit && (widget.documentUuid ?? '').isNotEmpty) {
      cubit.updateDocument(
        documentUuid: widget.documentUuid!,
        studentCode: payload.studentCode,
        name: payload.name,
        type: payload.type,
        expiryDate: payload.expiryDate,
        storagePath: payload.storagePath,
        mimeType: payload.mimeType,
        size: payload.size,
        notes: payload.notes,
      );
    } else {
      cubit.addDocument(
        studentCode: payload.studentCode,
        name: payload.name,
        type: payload.type,
        expiryDate: payload.expiryDate,
        storagePath: payload.storagePath,
        mimeType: payload.mimeType,
        size: payload.size,
        notes: payload.notes,
      );
    }
  }

  void _showWarningMessage(String message) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isWarning: true,
    );
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
        final selectedDate = result['date'] as DateTime;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (selectedDate.isBefore(today) || selectedDate.isAtSameMomentAs(today)) {
          _showWarningMessage('Expiry date must be a future date');
          return;
        }
        setState(() {
          _selectedExpiryDate = selectedDate;
        });
      }
    } catch (e) {
      CoreUtils.logApiError('Error opening calendar dialog: $e');
    }
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'heic'],
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
      CoreUtils.logApiError('Error picking file: $e');
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
            SizedBox(height: responsive.verticalSpacing),
            _buildNotesField(),
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
            return CustomButtonLayout(
              confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
              onPressedConfirm: () => _addDocument(context),
              showCancelButton: false,
              isForm: false,
              isLoading: state.isLoading,
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
            maxLength: _documentNameMaxLength,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              counterText: '',
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
      label: "Document Type",
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
        Text(
          'Expiry Date',
          style: labelStyle,
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

  Widget _buildNotesField() {
    final responsive = ResponsiveHelper(context);
    final labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: labelStyle,
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight * 2,
            maxHeight: responsive.inputFieldHeight * 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            maxLength: _notesMaxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add notes...',
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

