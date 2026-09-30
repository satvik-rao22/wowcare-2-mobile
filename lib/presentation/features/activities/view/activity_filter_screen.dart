import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_filter_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Activity feed filters (tags + activity types), school-wide.
///
/// Data access (tag map + activity types) lives in [ActivityFilterCubit]; this
/// View only renders state and owns the user's in-progress selections.
class ActivityFilterScreen extends StatefulWidget {
  const ActivityFilterScreen({
    super.key,
    required this.schoolCode,
    required this.classroomCode,
    this.initialFilters,
  });

  static const String routeName = '/activity-filter';

  final String schoolCode;
  final String classroomCode;
  final Map<String, List<String>>? initialFilters;

  @override
  State<ActivityFilterScreen> createState() => _ActivityFilterScreenState();
}

class _ActivityFilterScreenState extends State<ActivityFilterScreen> {
  static const List<String> _approvalStatusOptions = <String>[
    'Pending Admin Approval',
    'Approved',
    'Rejected',
    'Parent Acknowledgement Pending',
    'Acknowledged',
  ];

  List<String> _selectedTags = [];
  List<String> _selectedActivityTypes = [];
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters ?? const {};
    _selectedTags = List<String>.from(initial['Tags'] ?? const []);
    _selectedActivityTypes = List<String>.from(
      initial['Activity Type'] ?? const [],
    );
    _selectedStatuses = List<String>.from(initial['Status'] ?? const []);
  }

  /// Once options arrive, drop any pre-selected value that is no longer valid
  /// (mirrors the previous post-load pruning).
  void _pruneSelectionsToOptions(ActivityFilterState state) {
    setState(() {
      _selectedTags.removeWhere((t) => !state.tagOptions.contains(t));
      _selectedActivityTypes.removeWhere(
        (t) => !state.activityTypeOptions.contains(t),
      );
      _selectedStatuses.removeWhere((s) => !_approvalStatusOptions.contains(s));
    });
  }

  void _apply() {
    Navigator.pop<Map<String, List<String>>>(context, {
      'Tags': List<String>.from(_selectedTags),
      'Activity Type': List<String>.from(_selectedActivityTypes),
      'Status': List<String>.from(_selectedStatuses),
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivityFilterCubit, ActivityFilterState>(
      listenWhen: (prev, curr) =>
          curr.status == ActivityFilterStatus.loaded &&
          prev.status != ActivityFilterStatus.loaded,
      listener: (context, state) => _pruneSelectionsToOptions(state),
      builder: (context, state) {
        final responsive = ResponsiveHelper(context);
        return StaffFormLayout(
          title: 'Filter Activities',
          child: _buildBody(context, state),
          bottomBar: _buildBottomBar(context, responsive, state),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ResponsiveHelper responsive,
    ActivityFilterState state,
  ) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: safeAreaBottom,
      ),
      child: CustomButtonLayout(
        confirmButtonLabel: 'Apply Filters',
        onPressedConfirm: _apply,
        showCancelButton: false,
        isForm: false,
        isLoading: state.isLoading,
      ),
    );
  }

  Widget _buildBody(BuildContext context, ActivityFilterState state) {
    if (state.isLoading) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: 3,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          final label = index == 0
              ? 'Tags'
              : (index == 1 ? 'Activity Type' : 'Status');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.activityFilterShimmerLabel),
              const SizedBox(height: 8),
              const ShimmerLoader(height: 40),
            ],
          );
        },
      );
    }

    if (state.status == ActivityFilterStatus.error) {
      return AppErrorState(
        title: 'Could not load filter options.',
        onRetry: () => context.read<ActivityFilterCubit>().loadMetadata(
          schoolCode: widget.schoolCode,
        ),
      );
    }

    final tagOptions = state.tagOptions;
    final activityTypeOptions = state.activityTypeOptions;
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return CustomMultiSelectDropdown(
            label: 'Tags',
            hintText: 'Select tags',
            items: tagOptions,
            selectedItems: _selectedTags,
            labelBottomSpacing: 4,
            onChanged: (values) {
              setState(() => _selectedTags = List<String>.from(values));
            },
          );
        }
        if (index == 1) {
          return CustomMultiSelectDropdown(
            label: 'Activity Type',
            hintText: 'Select activity',
            items: activityTypeOptions,
            selectedItems: _selectedActivityTypes,
            labelBottomSpacing: 4,
            onChanged: (values) {
              setState(
                () => _selectedActivityTypes = List<String>.from(values),
              );
            },
          );
        }
        return CustomMultiSelectDropdown(
          label: 'Status',
          hintText: 'Select status',
          items: _approvalStatusOptions,
          selectedItems: _selectedStatuses,
          labelBottomSpacing: 4,
          onChanged: (values) {
            setState(() => _selectedStatuses = List<String>.from(values));
          },
        );
      },
    );
  }
}
