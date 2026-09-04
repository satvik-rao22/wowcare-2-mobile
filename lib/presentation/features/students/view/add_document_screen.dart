import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/storage/storage_service.dart';
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
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/students/cubit/student_document_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/activities/utils/resolve_logged_in_staff_code.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'dart:io';

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
    this.initialAssetCode,
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
  final String? initialAssetCode;
  final String? documentUuid;

  @override
  _AddStudentDocumentScreenState createState() =>
      _AddStudentDocumentScreenState();
}

class _AddStudentDocumentScreenState extends State<AddStudentDocumentScreen> {
  final TextEditingController _documentNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedDocumentType;
  DateTime? _selectedExpiryDate;
  String? _selectedFilePath;
  PlatformFile? _selectedFile;
  bool _isUploadingFile = false;
  int _uploadProgressPercent = 0;
  String? _uploadedAssetCode;
  String? _uploadedStoragePath;
  static const int _documentNameMaxLength = 100;
  static const int _notesMaxLength = 500;

  final List<String> _documentTypes = [
    'Birth Certificate',
    'Health Forms',
    'Registration Forms',
    'Special Program Forms',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      if (widget.initialDocumentName != null) {
        _documentNameController.text = widget.initialDocumentName!.trim();
      }
      // widget.initialDocumentType carries the raw API enum (e.g.
      // 'BIRTH_CERTIFICATE', matching what _toDocumentTypeEnum below sends on
      // save) - the Type dropdown's own items are the display labels
      // ('Birth Certificate'). Map back to the display label so the dropdown
      // actually shows the current value selected instead of appearing empty
      // (the raw enum string matches none of _documentTypes).
      _selectedDocumentType = _documentTypeFromApiValue(
        widget.initialDocumentType,
      );
      _selectedExpiryDate = widget.initialExpiryDate;
      _selectedFilePath = widget.initialFilePath;
      if (widget.initialDocumentNotes != null) {
        _notesController.text = widget.initialDocumentNotes!.trim();
      }
      _uploadedAssetCode = widget.initialAssetCode;
    }
  }

  /// Inverse of the enum mapping in [_addDocument]'s local
  /// `_toDocumentTypeEnum` - keep the two in sync if the type list ever
  /// changes.
  String? _documentTypeFromApiValue(String? apiValue) {
    switch ((apiValue ?? '').trim().toUpperCase()) {
      case 'BIRTH_CERTIFICATE':
        return 'Birth Certificate';
      case 'REGISTRATION_FORM':
        return 'Registration Forms';
      case 'SPECIAL_PROGRAM_FORM':
        return 'Special Program Forms';
      case 'HEALTH_FORM':
        return 'Health Forms';
      case 'OTHER':
        return 'Other';
      default:
        // Unrecognized/empty value - leave unselected rather than guessing.
        return null;
    }
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addDocument(BuildContext context) async {
    final name = _documentNameController.text.trim();
    if (name.isEmpty) {
      _showWarningMessage('Document name is required');
      return;
    }
    if (name.length > _documentNameMaxLength) {
      _showWarningMessage(
        'Document name must be at most $_documentNameMaxLength characters',
      );
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
      storagePath = _uploadedStoragePath ?? _selectedFile!.name;
      sizeBytes = _selectedFile!.size;
      mimeType = FilePickerUtils.getMimeType(_selectedFile!.extension);
      if (_uploadedAssetCode == null || _uploadedAssetCode!.trim().isEmpty) {
        _showWarningMessage('Please wait for file upload to complete');
        return;
      }
    } else if (widget.isEdit && widget.initialFilePath != null) {
      storagePath = widget.initialFilePath!;
      sizeBytes = (widget.initialFileSizeKb ?? 0) * 1024;
      mimeType = widget.initialMimeType ?? 'application/pdf';
    } else {
      _showWarningMessage('Please upload a document');
      return;
    }

    final cubit = context.read<StudentDocumentCubit>();
    final uploadedBy = await resolveLoggedInStaffCode();

    String _toDocumentTypeEnum(String uiValue) {
      switch (uiValue.trim()) {
        case 'Birth Certificate':
          return 'BIRTH_CERTIFICATE';
        case 'Registration Forms':
          return 'REGISTRATION_FORM';
        case 'Special Program Forms':
          return 'SPECIAL_PROGRAM_FORM';
        case 'Health Forms':
          return 'HEALTH_FORM';
        case 'Other':
        default:
          return 'OTHER';
      }
    }

    final documentType = _toDocumentTypeEnum(_selectedDocumentType!);

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
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
        assetCode: _uploadedAssetCode,
        uploadedBy: uploadedBy,
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
        assetCode: _uploadedAssetCode,
        uploadedBy: uploadedBy,
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
        final now = AppTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (selectedDate.isBefore(today) ||
            selectedDate.isAtSameMomentAs(today)) {
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
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...FilePickerUtils.allowedDocumentExtensions,
          ...FilePickerUtils.allowedImageExtensions,
          ...FilePickerUtils.allowedVideoExtensions,
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          _selectedFile = file;
          _selectedFilePath = file.name;
          _uploadedAssetCode = null;
          _uploadedStoragePath = null;
        });
        await _uploadSelectedFile(file);
      }
    } catch (e) {
      CoreUtils.logApiError('Error picking file: $e');
      _showWarningMessage('Error selecting file. Please try again.');
    }
  }

  Future<void> _uploadSelectedFile(PlatformFile selectedFile) async {
    try {
      setState(() {
        _isUploadingFile = true;
        _uploadProgressPercent = 0;
      });
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      final organizationCode =
          (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        _showWarningMessage('Missing school or organization context');
        return;
      }
      final selectedPath = selectedFile.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        _showWarningMessage('Selected file path is not available');
        return;
      }
      final file = File(selectedPath);
      if (!await file.exists()) {
        _showWarningMessage('Selected file is not accessible');
        return;
      }
      final mimeType = FilePickerUtils.getMimeType(selectedFile.extension);
      final uploadService = serviceLocator<ImageUploadService>();
      final uploadSession = await uploadService
          .createStudentDocumentUploadSession(
            studentCode: widget.studentCode,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
          );
      final mediaType = mimeType.startsWith('image/')
          ? 'IMAGE'
          : mimeType.startsWith('video/')
          ? 'VIDEO'
          : 'DOCUMENT';
      final presign = await uploadService.createAssetPresign(
        sessionCode: uploadSession.sessionCode,
        documentApiBasePath: uploadSession.documentApiBasePath,
        fileName: selectedFile.name,
        contentType: mimeType,
        contentLengthBytes: selectedFile.size,
        mediaType: mediaType,
        ownerType: 'STUDENT',
        ownerCode: widget.studentCode,
      );
      await uploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: mimeType,
        onProgress: (_, __, percent) {
          if (!mounted) return;
          setState(() => _uploadProgressPercent = percent.clamp(0, 100));
        },
      );
      await uploadService.completeAssetUpload(
        sessionCode: uploadSession.sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: uploadSession.documentApiBasePath,
      );
      await uploadService.waitUntilAssetsReady(
        sessionCode: uploadSession.sessionCode,
        expectedAssetCodes: <String>[presign.assetCode],
      );
      if (!mounted) return;
      // Asset is processed & READY — finish the upload now so the loader stops
      // and the "Add" button is enabled immediately. The delivery URL is only
      // used for display and falls back to the file name, so resolve it in the
      // background instead of keeping the spinner up (URL resolution can poll
      // for up to ~15s, which was needlessly gating the button).
      setState(() {
        _uploadedAssetCode = presign.assetCode;
        _uploadedStoragePath = selectedFile.name;
        _isUploadingFile = false;
        _uploadProgressPercent = 0;
      });
      uploadService
          .getMediaAssetUrlByCode(assetCode: presign.assetCode)
          .then((resolvedUrl) {
            final url = resolvedUrl.trim();
            if (mounted && url.isNotEmpty) {
              setState(() => _uploadedStoragePath = url);
            }
          })
          .catchError((_) {});
    } catch (e) {
      _showWarningMessage('Failed to upload file: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
          _uploadProgressPercent = 0;
        });
      }
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
        child: BlocBuilder<StudentDocumentCubit, StudentDocumentState>(
          builder: (context, state) {
            return CustomButtonLayout(
              confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
              cancelButtonLabel: 'Cancel',
              onPressedConfirm: () => _addDocument(context),
              onPressedCancel: () => Navigator.pop(context, false),
              showCancelButton: true,
              isForm: false,
              isLoading: state.isLoading || _isUploadingFile,
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
                      AppColors.primaryColor,
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
            style: AppTextStyles.label.copyWith(
              fontSize: responsive.labelFontSize,
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
                    _isUploadingFile
                        ? 'Uploading... $_uploadProgressPercent%'
                        : (_selectedFilePath ?? 'Choose a File'),
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
                    AppColors.primaryColor,
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
    final labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
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
