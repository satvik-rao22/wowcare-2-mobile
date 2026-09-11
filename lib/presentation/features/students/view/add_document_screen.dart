import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/students/view_model/student_document_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/staff/usecases/resolve_logged_in_staff_code_usecase.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

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
  static const int _documentNameMaxLength = 100;
  static const int _notesMaxLength = 500;

  /// One cubit instance for this screen (owns the form model + upload + submit);
  /// held as a field so edit mode can seed it in initState. Closed in dispose.
  final StudentDocumentCubit _cubit = serviceLocator<StudentDocumentCubit>();

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
      if (widget.initialDocumentNotes != null) {
        _notesController.text = widget.initialDocumentNotes!.trim();
      }
      // Controllers stay local (source of text truth); the form model + the
      // pre-existing asset seed the cubit.
      _cubit.initializeForEdit(
        documentType: widget.initialDocumentType,
        expiryDate: widget.initialExpiryDate,
        assetCode: widget.initialAssetCode,
      );
    }
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _notesController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _addDocument() async {
    final state = _cubit.state;
    final name = _documentNameController.text.trim();
    if (name.isEmpty) {
      _showWarningMessage(StudentStrings.documentNameIsRequired);
      return;
    }
    if (name.length > _documentNameMaxLength) {
      _showWarningMessage(
        'Document name must be at most $_documentNameMaxLength characters',
      );
      return;
    }
    if (state.documentType == null) {
      _showWarningMessage(StudentStrings.pleaseSelectADocumentType);
      return;
    }
    if (_notesController.text.length > _notesMaxLength) {
      _showWarningMessage('Notes must be at most $_notesMaxLength characters');
      return;
    }
    if (!widget.isEdit && !state.hasSelectedFile) {
      _showWarningMessage(StudentStrings.pleaseUploadADocument);
      return;
    }
    if (state.hasSelectedFile && !state.hasUploadedAsset) {
      _showWarningMessage(StudentStrings.pleaseWaitForFileUploadToComplete);
      return;
    }
    if (widget.studentCode.isEmpty) {
      _showWarningMessage(StudentStrings.studentCodeIsRequired);
      return;
    }

    final uploadedBy =
        await serviceLocator<ResolveLoggedInStaffCodeUseCase>()();

    await _cubit.submit(
      studentCode: widget.studentCode,
      name: name,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      uploadedBy: uploadedBy,
      isEdit: widget.isEdit,
      documentUuid: widget.documentUuid,
      initialFilePath: widget.initialFilePath,
      initialFileSizeKb: widget.initialFileSizeKb,
      initialMimeType: widget.initialMimeType,
    );
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
          initialDate: _cubit.state.expiryDate,
        ),
      );

      if (result != null && result['date'] != null) {
        final selectedDate = result['date'] as DateTime;
        final now = AppTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (selectedDate.isBefore(today) ||
            selectedDate.isAtSameMomentAs(today)) {
          _showWarningMessage(StudentStrings.expiryDateMustBeAFutureDate);
          return;
        }
        _cubit.setExpiryDate(selectedDate);
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
        final PlatformFile file = result.files.first;
        // The cubit owns the whole upload flow (session → presign → PUT →
        // complete → ready) + the upload state; the widget just hands it the
        // picked file.
        await _cubit.uploadFile(studentCode: widget.studentCode, file: file);
      }
    } catch (e) {
      CoreUtils.logApiError('Error picking file: $e');
      _showWarningMessage(StudentStrings.errorSelectingFilePleaseTryAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocProvider<StudentDocumentCubit>.value(
      value: _cubit,
      child: BlocListener<StudentDocumentCubit, StudentDocumentState>(
        listenWhen: (prev, curr) =>
            prev.submitStatus != curr.submitStatus ||
            (curr.uploadErrorMessage != null &&
                curr.uploadErrorMessage != prev.uploadErrorMessage),
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message!,
              isSuccess: true,
            );
            context.pop(true);
          } else if (state.isError && state.message != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message!,
              isError: true,
            );
          } else if (state.uploadErrorMessage != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.uploadErrorMessage!,
              isWarning: true,
            );
          }
        },
        child: _buildForm(responsive, safeAreaBottom),
      ),
    );
  }

  Widget _buildForm(ResponsiveHelper responsive, double safeAreaBottom) {
    return StaffFormLayout(
      title: widget.isEdit
          ? StudentStrings.editDocument
          : StudentStrings.addDocument,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildInputField(
              StudentStrings.documentName,
              StudentStrings.egReportCard,
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
            AppSpacing.gapVSm,
          ],
        ),
      ),
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.xs,
        ),
        decoration: AppSurfaces.card(borderRadius: BorderRadius.only( topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0), topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0), )),
        child: BlocBuilder<StudentDocumentCubit, StudentDocumentState>(
          builder: (context, state) {
            return CustomButtonLayout(
              confirmButtonLabel: widget.isEdit
                  ? StudentStrings.save
                  : StudentStrings.add,
              cancelButtonLabel: StudentStrings.cancel,
              onPressedConfirm: _addDocument,
              onPressedCancel: () => context.pop(false),
              showCancelButton: true,
              isForm: false,
              isLoading: state.isLoading || state.isUploading,
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
                style: TextStyle(color: AppColors.errorColor),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border.all(color: AppColors.inputBorderColor),
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
              hintStyle: labelStyle.copyWith(
                color: AppColors.attendanceMutedTextColor,
              ),
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
    // BlocBuilder (not context.watch<StudentDocumentCubit>() against this
    // State's own context) — this method is called from _buildForm, which
    // is built as `BlocProvider<StudentDocumentCubit>.value(... child:
    // _buildForm(...))` inside build() below: the PROVIDER doesn't exist
    // yet on this State's own context at the point _buildForm() runs, only
    // on the subtree it returns. BlocBuilder resolves the cubit from its
    // own (correctly descendant) context once mounted, not from here.
    return BlocBuilder<StudentDocumentCubit, StudentDocumentState>(
      builder: (context, state) {
        return CustomDropdown(
          label: StudentStrings.documentType,
          hintText: StudentStrings.select,
          items: _documentTypes,
          selectedItem: state.documentType,
          onSelect: (value) => _cubit.setDocumentType(value),
        );
      },
    );
  }

  Widget _buildDateField() {
    final responsive = ResponsiveHelper(context);
    final labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
    );

    // See _buildCustomDropdown's doc comment for why this is a BlocBuilder
    // rather than context.watch<StudentDocumentCubit>() against this
    // State's own context.
    return BlocBuilder<StudentDocumentCubit, StudentDocumentState>(
      builder: (context, state) {
        final selectedExpiryDate = state.expiryDate;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(StudentStrings.expiryDate, style: labelStyle),
            SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
            GestureDetector(
              onTap: _selectExpiryDate,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: responsive.inputFieldHeight,
                ),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  border: Border.all(color: AppColors.inputBorderColor),
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
                          selectedExpiryDate != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(selectedExpiryDate)
                              : StudentStrings.selectDate,
                          style: TextStyle(
                            color: selectedExpiryDate == null
                                ? AppColors.attendanceMutedTextColor
                                : AppColors.blackColor,
                            fontSize: responsive.inputFontSize,
                            fontFamily: AppFonts.body,
                          ),
                        ),
                      ),
                      AppIcon(
                        MediaRes.calender_icon,
                        height: responsive.isTablet ? 28.0 : 24.0,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFileUploadField() {
    final responsive = ResponsiveHelper(context);

    // See _buildCustomDropdown's doc comment for why this is a BlocBuilder
    // rather than context.watch<StudentDocumentCubit>() against this
    // State's own context.
    return BlocBuilder<StudentDocumentCubit, StudentDocumentState>(
      builder: (context, state) {
        // In edit mode with no newly-picked file, fall back to the existing file.
        final displayName = state.selectedFileName ?? widget.initialFilePath;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: AppTextStyles.label.copyWith(
                  fontSize: responsive.labelFontSize,
                ),
                children: [
                  const TextSpan(text: StudentStrings.uploadDocument),
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.errorColor),
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
                  border: Border.all(color: AppColors.inputBorderColor),
                  borderRadius: BorderRadius.circular(
                    responsive.isTablet ? 12.0 : 8.0,
                  ),
                  color: AppColors.whiteColor,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.isUploading
                            ? 'Uploading... ${state.uploadPercent}%'
                            : (displayName ?? StudentStrings.chooseAFile),
                        style: TextStyle(
                          color: displayName == null
                              ? AppColors.attendanceMutedTextColor
                              : AppColors.blackColor,
                          fontSize: responsive.inputFontSize,
                          fontFamily: AppFonts.body,
                        ),
                      ),
                    ),
                    AppIcon(
                      MediaRes.uploadIcon,
                      height: responsive.isTablet ? 28.0 : 24.0,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
        Text(StudentStrings.notes, style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight * 2,
            maxHeight: responsive.inputFieldHeight * 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border.all(color: AppColors.inputBorderColor),
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
              hintText: StudentStrings.addNotes,
              hintStyle: labelStyle.copyWith(
                color: AppColors.attendanceMutedTextColor,
              ),
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
