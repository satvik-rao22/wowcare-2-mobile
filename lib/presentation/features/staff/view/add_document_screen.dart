import 'package:flutter/material.dart';
import 'package:wowcare/core/storage/storage_service.dart';
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
import 'package:wowcare/presentation/features/staff/cubit/staff_document_cubit.dart';
import 'package:wowcare/domain/features/staff/entities/staff_document.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'package:wowcare/app/di/di.dart';
import 'dart:io';

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
  bool _isUploadingFile = false;
  int _uploadProgressPercent = 0;
  String? _uploadedAssetCode;
  String? _uploadedDocumentUrl;
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

  Future<void> _addDocument() async {
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
      mimeType = FilePickerUtils.getMimeType(_selectedFile!.extension);
      documentUrl = _uploadedDocumentUrl ?? _selectedFile!.name;
      if (_uploadedAssetCode == null || _uploadedAssetCode!.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please wait for file upload to complete',
          isWarning: true,
        );
        return;
      }
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
      assetCode: _uploadedAssetCode,
      expiryDate: _selectedExpiryDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedExpiryDate!)
          : null,
      documentNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;
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
          _uploadedDocumentUrl = null;
        });
        await _uploadSelectedFile(file);
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
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Missing school or organization context',
          isWarning: true,
        );
        return;
      }
      final selectedPath = selectedFile.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Selected file path is not available',
          isWarning: true,
        );
        return;
      }
      final file = File(selectedPath);
      if (!await file.exists()) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Selected file is not accessible',
          isWarning: true,
        );
        return;
      }
      final mimeType = FilePickerUtils.getMimeType(selectedFile.extension);
      final uploadService = serviceLocator<ImageUploadService>();
      final uploadSession = await uploadService
          .createStaffDocumentUploadSession(
            staffCode: widget.staffCode,
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
        ownerType: 'STAFF',
        ownerCode: widget.staffCode,
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
      final resolvedUrl = await uploadService.getMediaAssetUrlByCode(
        assetCode: presign.assetCode,
      );
      if (!mounted) return;
      setState(() {
        _uploadedAssetCode = presign.assetCode;
        _uploadedDocumentUrl = resolvedUrl.trim().isNotEmpty
            ? resolvedUrl.trim()
            : selectedFile.name;
      });
    } catch (e) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to upload file: ${e.toString()}',
        isError: true,
      );
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

        bottomBar: BlocBuilder<StaffDocumentCubit, StaffDocumentState>(
          builder: (context, state) {
            return CustomButtonLayout(
              confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
              onPressedConfirm: _addDocument,
              showCancelButton: false,
              isForm: false,
              isLoading: state.isLoading || _isUploadingFile,
            );
          },
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
