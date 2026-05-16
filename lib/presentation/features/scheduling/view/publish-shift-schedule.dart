import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_app_bar.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import '../cubit/schedule_form_cubit.dart';
import '../cubit/schedule_form_state.dart';
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
    return BlocProvider(
      create: (_) => serviceLocator<ScheduleFormCubit>(),
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
      child: Scaffold(
        appBar: CustomAppBar(hasBackButton: true),
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
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: CustomButtonLayout(
              confirmButtonLabel: 'Publish',
              cancelButtonLabel: 'Cancel',
              onPressedConfirm: isSubmitting
                  ? null
                  : () => _handlePublish(context),
              onPressedCancel: () => Navigator.pop(context),
              showCancelButton: true,
              isForm: false,
              isLoading: isSubmitting,
            ),
          ),
        ),
      ),
    );
  }
}
