import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../staff/cubit/staff_cubit.dart';
import '../cubit/Add-Shift/cubit/edit_and_publish_schedule_form_cubit.dart';
import '../cubit/Add-Shift/cubit/edit_and_publish_schedule_form_state.dart';
import '../widgets/publish_option_card.dart';

class PublishShiftScheduleScreen extends StatefulWidget {
  const PublishShiftScheduleScreen({super.key});

  static const String routeName = '/publish-shift-schedule';

  @override
  State<PublishShiftScheduleScreen> createState() =>
      _PublishShiftScheduleScreenState();
}

class _PublishShiftScheduleScreenState
    extends State<PublishShiftScheduleScreen> {
  PublishType _selectedValue = PublishType.untilDate;
  DateTime? _publishUntilDate;
  Map<String, dynamic>? _basePayload;
  bool _didLoadArgs = false;
  String? _selectedStaffName;
  String? _selectedStaffCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    _didLoadArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _basePayload = Map<String, dynamic>.from(args);
    }
  }

  void _handlePublish(BuildContext blocContext) async {
    if (_selectedStaffCode == null) {
      CoreUtils.showTopSnackBar(
        context: blocContext,
        message: 'Please select staff',
        isWarning: true,
      );
      return;
    }
    if (_basePayload == null) {
      CoreUtils.showTopSnackBar(
        context: blocContext,
        message: 'Missing schedule data. Please create the shift again.',
        isWarning: true,
      );
      return;
    }

    if (_selectedValue == PublishType.untilDate && _publishUntilDate == null) {
      CoreUtils.showTopSnackBar(
        context: blocContext,
        message: 'Please select publish until date',
        isWarning: true,
      );
      return;
    }

    final payload = Map<String, dynamic>.from(_basePayload!);
    payload['publish'] = true;

    if (_selectedValue == PublishType.untilDate && _publishUntilDate != null) {
      payload['repeat'] = true;
      payload['repeatUntil'] = DateFormat(
        'yyyy-MM-dd',
      ).format(_publishUntilDate!);
    }

    if (!mounted) return;
    blocContext.read<ScheduleFormCubit>().saveSchedule(data: payload);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<ScheduleFormCubit>()),

        BlocProvider(
          create: (_) => serviceLocator<StaffCubit>()..loadInitial(),
        ),
      ],
      child: BlocListener<ScheduleFormCubit, ScheduleFormState>(
        listener: (context, state) {
          if (state is ScheduleFormSuccess) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Shifts published successfully',
              isSuccess: true,
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (state is ScheduleFormError) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message,
              isWarning: true,
            );
          }
        },
        child: BlocBuilder<ScheduleFormCubit, ScheduleFormState>(
          builder: (context, state) {
            return _buildScaffold(
              context,
              isSubmitting: state is ScheduleFormSubmitting,
            );
          },
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, {required bool isSubmitting}) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: GlobalScaffold(
        hasBackButton: true,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                'Publish Shifts',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),

              // Staff Drop Down Selection
              BlocBuilder<StaffCubit, StaffState>(
                builder: (context, staffState) {
                  final staffList = staffState.items
                      .map((s) => {'code': s.code, 'name': s.name})
                      .toList();

                  return CustomDropdown(
                    label: 'Staff',
                    hintText: staffState.isLoading
                        ? 'Loading staff...'
                        : 'Select Staff',

                    isRequired: true,

                    selectedItem: _selectedStaffName,

                    items: staffList
                        .map<String>((e) => e['name'] as String)
                        .toList(),

                    onSelect: (val) {
                      final found = staffList.firstWhere(
                        (e) => e['name'] == val,
                        orElse: () => {},
                      );

                      if (found.isNotEmpty) {
                        setState(() {
                          _selectedStaffName = found['name'] as String;

                          _selectedStaffCode = found['code'] as String;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PublishOptionCard(
                  untilDateTitle: 'Publish Until Date',
                  publishAllTitle: 'Publish All',
                  selectedValue: _selectedValue,
                  initialDate: _publishUntilDate,
                  onDateSelected: (date) {
                    setState(() => _publishUntilDate = date);
                  },
                  onChanged: (value) {
                    setState(() => _selectedValue = value);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        showCustomNavigationBarButtons: true,
        onPressedConfirm: isSubmitting ? null : () => _handlePublish(context),

        onPressedCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
