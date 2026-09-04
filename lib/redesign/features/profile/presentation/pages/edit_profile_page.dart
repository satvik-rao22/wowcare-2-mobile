import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/features/profile/cubit/edit_profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/docked_bar.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/value_field.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// 13b. The eight fields a person may change about themselves.
///
/// Email and country are drawn and refused rather than left out, and every
/// refusal sits on the field that caused it, which is what makes a form of
/// this length fixable.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.user?.id ?? '';

    return BlocProvider<EditProfileCubit>(
      create: (_) {
        final cubit = redesignLocator<EditProfileCubit>(param1: userId);
        unawaited(cubit.load());
        return cubit;
      },
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatelessWidget {
  const _EditProfileView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<EditProfileCubit, EditProfileState>(
        listenWhen: (previous, current) =>
            previous.isSaved != current.isSaved ||
            previous.hasSaveFailed != current.hasSaveFailed,
        listener: (context, state) {
          if (state.isSaved) {
            showAppToast(context, ProfileStrings.profileSaved);
            Navigator.of(context).pop();
          } else if (state.hasSaveFailed) {
            showAppToast(
              context,
              ProfileStrings.saveFailed,
              tone: ToastTone.error,
            );
            context.read<EditProfileCubit>().clearFailure();
          }
        },
        builder: (context, state) {
          if (state.isFailed) {
            return ScreenScaffold(
              header: const AppHeaderBar(
                title: ProfileStrings.editMyProfile,
                isDetail: true,
                leading: BackKey(),
              ),
              body: Center(
                child: ErrorState(
                  message: ProfileStrings.loadFailedTitle,
                  onRetry: () =>
                      unawaited(context.read<EditProfileCubit>().load()),
                ),
              ),
            );
          }

          return ScreenScaffold(
            header: const AppHeaderBar(
              title: ProfileStrings.editMyProfile,
              isDetail: true,
              leading: BackKey(),
            ),
            bodyPadding: EdgeInsets.zero,
            bottomBar: _Footer(state: state),
            body: state.isLoading ? const LoadingState() : _Form(state: state),
          );
        },
      );
}

/// Every field 13b edits, seeded once from the record as it was loaded.
class _Form extends StatefulWidget {
  const _Form({required this.state});

  final EditProfileState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _zip;

  EditProfileState get state => widget.state;

  @override
  void initState() {
    super.initState();
    // Seeded once. After this the fields are the source of truth and the
    // cubit follows them.
    final form = state.form;
    _firstName = TextEditingController(text: form.firstName);
    _lastName = TextEditingController(text: form.lastName);
    _phone = TextEditingController(text: form.phone);
    _street = TextEditingController(text: form.street);
    _line2 = TextEditingController(text: form.line2);
    _city = TextEditingController(text: form.city);
    _zip = TextEditingController(text: form.zipCode);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _street.dispose();
    _line2.dispose();
    _city.dispose();
    _zip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditProfileCubit>();
    final form = state.form;
    final errors = state.errors;
    final isRequired = state.isAddressRequired;

    return ListView(
      padding: ProfileSizes.formPad,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ProfileSizes.formGap,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ProfileSizes.fieldRowGap,
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    label: ProfileStrings.firstName,
                    isRequired: true,
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    errorText: errors.firstName,
                    onChanged: (v) => cubit.edit(form.copyWith(firstName: v)),
                  ),
                ),
                Expanded(
                  child: AppTextField(
                    label: ProfileStrings.lastName,
                    isRequired: true,
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    errorText: errors.lastName,
                    onChanged: (v) => cubit.edit(form.copyWith(lastName: v)),
                  ),
                ),
              ],
            ),
            ValueField(
              label: ProfileStrings.email,
              value: state.email,
              isLocked: true,
              showLockTag: true,
              helpText: ProfileStrings.emailHelp,
            ),
            AppTextField(
              label: ProfileStrings.phoneNumber,
              isRequired: true,
              controller: _phone,
              keyboardType: TextInputType.phone,
              errorText: errors.phone,
              onChanged: (v) => cubit.edit(form.copyWith(phone: v)),
            ),
            AppTextField(
              label: ProfileStrings.street,
              isRequired: isRequired,
              controller: _street,
              textCapitalization: TextCapitalization.words,
              errorText: errors.street,
              onChanged: (v) => cubit.edit(form.copyWith(street: v)),
            ),
            AppTextField(
              label: ProfileStrings.addressLine2,
              controller: _line2,
              textCapitalization: TextCapitalization.words,
              errorText: errors.line2,
              onChanged: (v) => cubit.edit(form.copyWith(line2: v)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ProfileSizes.fieldRowGap,
              children: <Widget>[
                Expanded(
                  flex: ProfileSizes.cityFlex,
                  child: AppTextField(
                    label: ProfileStrings.city,
                    isRequired: isRequired,
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    errorText: errors.city,
                    onChanged: (v) => cubit.edit(form.copyWith(city: v)),
                  ),
                ),
                Expanded(
                  flex: ProfileSizes.zipFlex,
                  child: AppTextField(
                    label: ProfileStrings.zipCode,
                    isRequired: isRequired,
                    controller: _zip,
                    keyboardType: TextInputType.number,
                    errorText: errors.zipCode,
                    onChanged: (v) => cubit.edit(form.copyWith(zipCode: v)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ProfileSizes.fieldRowGap,
              children: <Widget>[
                Expanded(
                  child: DropdownField(
                    label: ProfileStrings.state,
                    isRequired: isRequired,
                    value: form.state.isEmpty ? null : form.state,
                    placeholder: ProfileStrings.chooseState,
                    errorText: errors.state,
                    onTap: () => unawaited(_pickState(context)),
                  ),
                ),
                Expanded(
                  child: ValueField(
                    label: ProfileStrings.country,
                    value: state.country,
                    isLocked: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickState(BuildContext context) async {
    final cubit = context.read<EditProfileCubit>();
    final picked = await SingleSelectSheet.show<String>(
      context,
      title: ProfileStrings.chooseState,
      selected: state.form.state.isEmpty ? null : state.form.state,
      searchable: true,
      options: <SelectOption<String>>[
        for (final name in state.stateNames)
          SelectOption<String>(value: name, label: name),
      ],
    );
    if (picked != null) cubit.edit(state.form.copyWith(state: picked));
  }
}

/// Cancel, and the one pink key.
class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final EditProfileState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditProfileCubit>();

    return DockedBar(
      child: Row(
        spacing: ProfileSizes.footerGap,
        children: <Widget>[
          Expanded(
            flex: ProfileSizes.cancelFlex,
            child: SecondaryKey(
              label: AppStrings.cancel,
              padding: ProfileSizes.footerKeyPad,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            flex: ProfileSizes.saveFlex,
            child: PrimaryKey(
              label: AppStrings.save,
              enabled: state.canSave,
              isLoading: state.isSaving,
              padding: ProfileSizes.footerKeyPad,
              onTap: () => unawaited(cubit.save()),
            ),
          ),
        ],
      ),
    );
  }
}
