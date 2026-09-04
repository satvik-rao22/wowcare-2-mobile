import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/staff/cubit/edit_staff_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/note_well.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

/// Added. 6c's fields card carries an Edit key and the frames stop there, so
/// this is the smallest screen it can lead to: name, contact and address.
///
/// Designation, role, classrooms and status are not on this form. They decide
/// what a person can reach, so an Admin sets them elsewhere, and that is what
/// lets a staff member keep their own details up to date safely.
class EditStaffPage extends StatelessWidget {
  const EditStaffPage({required this.staffId, super.key});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final lens = StaffLens(
      persona: session.persona,
      viewerId: session.user?.id ?? '',
      viewerClassroom: session.user?.classroomName,
    );

    return BlocProvider<EditStaffCubit>(
      create: (_) {
        final cubit = redesignLocator<EditStaffCubit>(
          param1: staffId,
          param2: lens,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _EditStaffView(),
    );
  }
}

class _EditStaffView extends StatefulWidget {
  const _EditStaffView();

  @override
  State<_EditStaffView> createState() => _EditStaffViewState();
}

/// The nine controllers are made once and filled when the record lands. A
/// controller built inside `build` would be rebuilt on every keystroke and
/// throw the caret back to the start of the field.
class _EditStaffViewState extends State<_EditStaffView> {
  final Map<StaffField, TextEditingController> _text =
      <StaffField, TextEditingController>{};
  final Map<String, TextEditingController> _address =
      <String, TextEditingController>{};

  static const String _street = 'street';
  static const String _line2 = 'line2';
  static const String _city = 'city';
  static const String _state = 'state';
  static const String _zip = 'zip';

  bool _isSeeded = false;

  TextEditingController _field(StaffField field) =>
      _text.putIfAbsent(field, TextEditingController.new);

  TextEditingController _addressField(String key) =>
      _address.putIfAbsent(key, TextEditingController.new);

  void _seed(StaffDetailsDraft draft) {
    if (_isSeeded) return;
    _isSeeded = true;
    _field(StaffField.firstName).text = draft.firstName;
    _field(StaffField.lastName).text = draft.lastName;
    _field(StaffField.email).text = draft.email;
    _field(StaffField.phone).text = draft.phone;
    _addressField(_street).text = draft.street;
    _addressField(_line2).text = draft.line2;
    _addressField(_city).text = draft.city;
    _addressField(_state).text = draft.state;
    _addressField(_zip).text = draft.zipCode;
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    for (final controller in _address.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditStaffCubit>();

    return BlocListener<EditStaffCubit, EditStaffState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == EditStaffStatus.editing) _seed(state.draft);
        if (!state.isSaved) return;
        showAppToast(context, StaffStrings.saved);
        Navigator.of(context).pop(state.profile);
      },
      child: BlocBuilder<EditStaffCubit, EditStaffState>(
        builder: (context, state) => ScreenScaffold(
          header: const AppHeaderBar(
            title: StaffStrings.editTitle,
            isDetail: true,
            leading: BackKey(),
          ),
          bottomBar: state.isLoading || state.isFailed
              ? null
              : _Footer(state: state, cubit: cubit),
          scrollable: true,
          body: _body(context, state, cubit),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    EditStaffState state,
    EditStaffCubit cubit,
  ) {
    if (state.isLoading) return const LoadingState();
    if (state.isFailed) {
      return Center(
        child: ErrorState(
          title: StaffStrings.couldNotReachTitle,
          message: StaffStrings.couldNotReachBody,
          onRetry: () => unawaited(cubit.load()),
        ),
      );
    }

    _seed(state.draft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.wizardFieldGap,
      children: <Widget>[
        const SectionEyebrow(label: StaffStrings.contactSection),
        AppTextField(
          label: StaffStrings.firstName,
          isRequired: true,
          controller: _field(StaffField.firstName),
          textCapitalization: TextCapitalization.words,
          errorText: state.errorFor(StaffField.firstName),
          onChanged: cubit.setFirstName,
        ),
        AppTextField(
          label: StaffStrings.lastName,
          isRequired: true,
          controller: _field(StaffField.lastName),
          textCapitalization: TextCapitalization.words,
          errorText: state.errorFor(StaffField.lastName),
          onChanged: cubit.setLastName,
        ),
        AppTextField(
          label: StaffStrings.workEmail,
          isRequired: true,
          controller: _field(StaffField.email),
          keyboardType: TextInputType.emailAddress,
          errorText: state.errorFor(StaffField.email),
          onChanged: cubit.setEmail,
        ),
        AppTextField(
          label: StaffStrings.phone,
          isRequired: true,
          controller: _field(StaffField.phone),
          keyboardType: TextInputType.phone,
          errorText: state.errorFor(StaffField.phone),
          onChanged: cubit.setPhone,
        ),
        const SectionEyebrow(label: StaffStrings.addressSection),
        AppTextField(
          label: StaffStrings.street,
          controller: _addressField(_street),
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.setStreet,
        ),
        AppTextField(
          label: StaffStrings.addressLine2,
          controller: _addressField(_line2),
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.setLine2,
        ),
        AppTextField(
          label: StaffStrings.city,
          controller: _addressField(_city),
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.setCity,
        ),
        Row(
          spacing: StaffSizes.wizardFieldGap,
          children: <Widget>[
            Expanded(
              child: AppTextField(
                label: StaffStrings.state,
                controller: _addressField(_state),
                textCapitalization: TextCapitalization.characters,
                onChanged: cubit.setState,
              ),
            ),
            Expanded(
              child: AppTextField(
                label: StaffStrings.zipCode,
                controller: _addressField(_zip),
                keyboardType: TextInputType.number,
                onChanged: cubit.setZipCode,
              ),
            ),
          ],
        ),
        const NoteWell(
          title: StaffStrings.permissionsSection,
          body: StaffStrings.adminOnlyNote,
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.cubit});

  final EditStaffState state;
  final EditStaffCubit cubit;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    // The bottom slot hands its child a loose height as tall as the screen,
    // and a key centres its face with an `Align`, which would take all of it.
    // `IntrinsicHeight` holds the row to the height its key actually needs.
    return IntrinsicHeight(
      child: Container(
        padding: StaffSizes.dockedBarPad.copyWith(
          bottom: StaffSizes.dockedBarPad.bottom + context.safeArea.bottom,
        ),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.barLine)),
        ),
        child: PrimaryKey(
          label: AppStrings.save,
          isLoading: state.isSaving,
          enabled: state.canEdit,
          onTap: () => unawaited(cubit.submit()),
        ),
      ),
    );
  }
}
