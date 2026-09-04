import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/trough.dart';
import 'package:wowcare/redesign/features/students/cubit/student_documents_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/date_field.dart';
import 'package:wowcare/redesign/features/students/students_formats.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// 5f's one card, in whichever of its four states the upload is in.
///
/// The same card throughout, rather than four: the file, its type and its
/// expiry are the same three answers whether they are being asked for, sent,
/// saved or retried, and moving them between cards would lose them.
class UploadDocumentCard extends StatelessWidget {
  const UploadDocumentCard({required this.state, super.key});

  final StudentDocumentsState state;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StudentsSizes.uploadCardGap,
      children: <Widget>[
        _header(context),
        if (state.showsProgress) _progress(context),
        if (state.showsFields) ..._fields(context),
        if (state.isDone || state.hasUploadFailed) _note(context),
        _keys(context),
      ],
    ),
  );

  // --- Header ---------------------------------------------------------------

  Widget _header(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: AppSizes.rowGap,
      children: <Widget>[
        SurfaceBox(
          surface: AppSurfaces.glyphTile(
            c,
            fill: _chipFill(c),
            radius: AppRadii.inner,
          ),
          width: StudentsSizes.uploadChip,
          height: StudentsSizes.uploadChip,
          alignment: Alignment.center,
          child: Text(
            _chipText,
            style: StudentsTextStyles.uploadChip.copyWith(color: _chipInk(c)),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSizes.rowTextGap,
            children: <Widget>[
              Text(
                _title,
                style: StudentsTextStyles.uploadTitle.copyWith(color: c.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _subtitle,
                style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _chipText => state.draft.fileName == null
      ? StudentsStrings.glyphAdd
      : state.draft.kind == DocumentKind.image
      ? StudentsStrings.kindImage
      : StudentsStrings.kindPdf;

  Color _chipFill(Colourway c) => switch (state.upload) {
    UploadStatus.idle => c.altWell,
    UploadStatus.sending => c.pinkBg,
    UploadStatus.done => c.successBg,
    UploadStatus.failed => c.dangerBg,
  };

  Color _chipInk(Colourway c) => switch (state.upload) {
    UploadStatus.idle => c.ink2,
    UploadStatus.sending => c.onPinkTint,
    UploadStatus.done => c.successFg,
    UploadStatus.failed => c.dangerFg,
  };

  String get _title => state.draft.fileName ?? StudentsStrings.addDocumentTitle;

  String get _subtitle {
    final size = StudentsFormats.fileSize(state.draft.sizeKb);
    return switch (state.upload) {
      UploadStatus.idle => StudentsStrings.addDocumentSub,
      UploadStatus.sending => StudentsStrings.uploadingSub(
        size,
        state.percentLabel,
      ),
      UploadStatus.done => StudentsStrings.onFileSub(size),
      UploadStatus.failed => StudentsStrings.stoppedSub(state.percentLabel),
    };
  }

  // --- The bar, the fields and the note -------------------------------------

  Widget _progress(BuildContext context) {
    final c = context.colours;
    return Trough(
      fraction: state.percentSent,
      height: StudentsSizes.progressHeight,
      fill: switch (state.upload) {
        UploadStatus.done => c.success,
        UploadStatus.failed => c.danger,
        _ => c.pink,
      },
    );
  }

  List<Widget> _fields(BuildContext context) {
    final cubit = context.read<StudentDocumentsCubit>();
    return <Widget>[
      DropdownField(
        label: StudentsStrings.whatIsIt,
        isRequired: true,
        value: state.draft.type,
        placeholder: StudentsStrings.pickType,
        enabled: !state.isSending,
        onTap: () => unawaited(_pickType(context)),
      ),
      DateField(
        label: StudentsStrings.expires,
        value: state.draft.expiryDate,
        onChanged: cubit.setExpiry,
      ),
    ];
  }

  Widget _note(BuildContext context) {
    final c = context.colours;
    final isDone = state.isDone;

    return SurfaceBox(
      surface: AppSurfaces.glyphTile(
        c,
        fill: isDone ? c.successBg : c.dangerBg,
        radius: AppRadii.inner,
      ),
      padding: StudentsSizes.uploadNotePad,
      child: Text(
        isDone
            ? StudentsStrings.savedNote(state.firstName, state.draft.type ?? '')
            : StudentsStrings.failedNote,
        style: AppTextStyles.noteText.copyWith(
          color: isDone ? c.successFg : c.dangerFg,
        ),
      ),
    );
  }

  // --- The keys -------------------------------------------------------------

  Widget _keys(BuildContext context) {
    final cubit = context.read<StudentDocumentsCubit>();

    return Row(
      spacing: StudentsSizes.detailKeyGap,
      children: <Widget>[
        SecondaryKey(
          label: _secondaryLabel,
          expand: false,
          padding: StudentsSizes.uploadSecondaryPad,
          onTap: () => _onSecondary(context, cubit),
        ),
        Expanded(
          child: PrimaryKey(
            label: _primaryLabel,
            enabled: !state.isSending && state.draft.type != null,
            isLoading: state.isSending,
            onTap: () => unawaited(_onPrimary(cubit)),
          ),
        ),
      ],
    );
  }

  String get _secondaryLabel => switch (state.upload) {
    UploadStatus.idle => StudentsStrings.camera,
    UploadStatus.sending => AppStrings.cancel,
    UploadStatus.done => StudentsStrings.view,
    UploadStatus.failed => StudentsStrings.discard,
  };

  String get _primaryLabel => switch (state.upload) {
    UploadStatus.idle => StudentsStrings.chooseFile,
    UploadStatus.sending => StudentsStrings.sending,
    UploadStatus.done => StudentsStrings.addAnother,
    UploadStatus.failed => StudentsStrings.retry,
  };

  void _onSecondary(BuildContext context, StudentDocumentsCubit cubit) {
    switch (state.upload) {
      case UploadStatus.idle:
        unawaited(cubit.chooseFile(fromCamera: true));
      case UploadStatus.sending || UploadStatus.failed:
        cubit.reset();
      case UploadStatus.done:
        showAppToast(context, StudentsStrings.viewSoon);
    }
  }

  Future<void> _onPrimary(StudentDocumentsCubit cubit) async {
    switch (state.upload) {
      case UploadStatus.idle:
        await cubit.chooseFile();
      case UploadStatus.sending:
        return;
      case UploadStatus.done:
        cubit.reset();
      case UploadStatus.failed:
        await cubit.send();
    }
  }

  Future<void> _pickType(BuildContext context) async {
    final cubit = context.read<StudentDocumentsCubit>();
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: StudentsStrings.pickType,
      selected: state.draft.type,
      options: <SelectOption<String>>[
        for (final type in StudentsStrings.documentTypes)
          SelectOption<String>(value: type, label: type),
      ],
    );
    if (picked != null) cubit.setType(picked);
  }
}
