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
import 'package:wowcare/presentation/features/staff/cubit/staff_document_cubit.dart';
import 'package:wowcare/domain/features/staff/entities/staff_document.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({
    super.key,
    required this.staffCode,
    this.isEdit = false,
    this.documentUuid,
    this.initialDocumentName,
    this.initialDocumentType,
    this.initialExpiryDate,
    this.initialFilePath,
    this.initialMimeType,
    this.initialFileSizeKb,
    this.initialDocumentNotes,
  });
  static const String routeName = '/add-document-screen';

  final String staffCode;
  final bool isEdit;
  final String? documentUuid;
  final String? initialDocumentName;
  final String? initialDocumentType;
  final DateTime? initialExpiryDate;
  final String? initialFilePath;
  final String? initialMimeType;
  final int? initialFileSizeKb;
  final String? initialDocumentNotes;

  @override
  _AddDocumentScreenState createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final TextEditingController _documentNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedDocumentType;
  DateTime? _selectedExpiryDate;
  String? _selectedFilePath;
  PlatformFile? _selectedFile;
  static const int _documentNameMaxLength = 100;
  static const int _notesMaxLength = 500;

  final List<String> _documentTypes = [
    'Educational',
    'Training',
    'Health',
    'Employment',
    'Resume',
    'Other',
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

  void _addDocument() {
    final name = _documentNameController.text.trim();
    if (name.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Document name is required',
        isWarning: true,
      );
      return;
    }
    if (name.length > _documentNameMaxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Document name must be at most $_documentNameMaxLength characters',
        isWarning: true,
      );
      return;
    }

    if (_selectedDocumentType == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a document type',
        isWarning: true,
      );
      return;
    }

    if (_notesController.text.length > _notesMaxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Notes must be at most $_notesMaxLength characters',
        isWarning: true,
      );
      return;
    }

    // In edit mode, file upload is optional (can use existing file)
    if (!widget.isEdit && _selectedFile == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please upload a document',
        isWarning: true,
      );
      return;
    }

    // Use new file if selected, otherwise use existing file URL in edit mode
    String documentUrl;
    int fileSizeKb;
    String mimeType;

    if (_selectedFile != null) {
      fileSizeKb = (_selectedFile!.size / 1024).ceil();
      final extension = _selectedFile!.extension?.toLowerCase() ?? '';
      mimeType = _getMimeType(extension);
      documentUrl = _selectedFile!.name;
    } else if (widget.isEdit && widget.initialFilePath != null) {
      // Use existing file info in edit mode
      documentUrl = widget.initialFilePath!;
      fileSizeKb = widget.initialFileSizeKb ?? 0;
      mimeType = widget.initialMimeType ?? 'application/pdf';
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please upload a document',
        isWarning: true,
      );
      return;
    }

    final document = StaffDocument(
      documentType: _selectedDocumentType!,
      documentName: name,
      documentUrl: documentUrl,
      documentSizeKb: fileSizeKb,
      mimeType: mimeType,
      expiryDate: _selectedExpiryDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedExpiryDate!)
          : null,
      documentNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (widget.isEdit && widget.documentUuid != null) {
      context.read<StaffDocumentCubit>().updateDocument(
        documentUuid: widget.documentUuid!,
        staffCode: widget.staffCode,
        document: document,
      );
    } else {
      context.read<StaffDocumentCubit>().addDocument(
        staffCode: widget.staffCode,
        document: document,
      );
    }
  }

  String _getMimeType(String extension) {
    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
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
        if (selectedDate.isBefore(today) ||
            selectedDate.isAtSameMomentAs(today)) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Expiry date must be a future date',
            isWarning: true,
          );
          return;
        }
        setState(() {
          _selectedExpiryDate = selectedDate;
        });
      }
    } catch (e) {
      print('Error opening calendar dialog: $e');
    }
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
        ],
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
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Error selecting file. Please try again.',
        isWarning: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocListener<StaffDocumentCubit, StaffDocumentState>(
      listener: (context, state) {
        if (state.isSuccess && state.message != null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.message!,
            isSuccess: true,
          );
          // Pop with success result to trigger refresh in parent
          Navigator.pop(context, true);
        } else if (state.isError && state.message != null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.message!,
            isError: true,
          );
        }
      },
      child: StaffFormLayout(
        title: widget.isEdit ? "Edit Document" : "Add Document",
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDocumentNameField(),
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
            bottom: safeAreaBottom,
            left: 16,
            right: 16,
            top: 8,
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
          child: BlocBuilder<StaffDocumentCubit, StaffDocumentState>(
            builder: (context, state) {
              return CustomButtonLayout(
                confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
                onPressedConfirm: _addDocument,
                showCancelButton: false,
                isForm: false,
                isLoading: state.isLoading,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentNameField() {
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
              const TextSpan(text: 'Document'),
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
            controller: _documentNameController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: _documentNameMaxLength,
            decoration: InputDecoration(
              hintText: 'E.g. Report Card',
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
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expiry Date', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: _selectExpiryDate,
          child: Container(
            constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0x66573353)),
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 12.0 : 8.0,
              ),
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
                          ? DateFormat(
                              'MMM dd, yyyy',
                            ).format(_selectedExpiryDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _selectedExpiryDate == null
                            ? Colors.grey
                            : Colors.black,
                        fontSize: responsive.inputFontSize,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    MediaRes.calender_icon,
                    height: responsive.isTablet ? 28.0 : 24.0,
                    colorFilter: const ColorFilter.mode(
                      Color(0xff573353),
                      BlendMode.srcIn,
                    ),
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
            style: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: [
              const TextSpan(text: 'Upload Document'),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
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
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 12.0 : 8.0,
              ),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedFilePath ?? 'Choose a File',
                    style: TextStyle(
                      color: _selectedFilePath == null
                          ? Colors.grey
                          : Colors.black,
                      fontSize: responsive.inputFontSize,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                SvgPicture.asset(
                  MediaRes.uploadIcon,
                  height: responsive.isTablet ? 28.0 : 24.0,
                  colorFilter: const ColorFilter.mode(
                    Color(0xff573353),
                    BlendMode.srcIn,
                  ),
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
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight * 2,
            maxHeight: responsive.inputFieldHeight * 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
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
