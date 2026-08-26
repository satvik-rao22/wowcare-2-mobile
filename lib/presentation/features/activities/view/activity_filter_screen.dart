import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/activities/cubit/activity_filter_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
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
    this.forGuardian = false,
  });

  static const String routeName = '/activity-filter';

  final String schoolCode;
  final String classroomCode;
  final Map<String, List<String>>? initialFilters;

  /// Guardian (parent) variant: Activity Type is the only filter offered.
  /// Student tags and the approval workflow are staff/admin concerns, and
  /// activity types parents cannot see are dropped from the type options.
  final bool forGuardian;

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
    _selectedActivityTypes =
        List<String>.from(initial['Activity Type'] ?? const []);
    _selectedStatuses = List<String>.from(initial['Status'] ?? const []);
  }

  /// Once options arrive, drop any pre-selected value that is no longer valid
  /// (mirrors the previous post-load pruning).
  void _pruneSelectionsToOptions(ActivityFilterState state) {
    setState(() {
      // Hidden sections carry their incoming selection through untouched —
      // their options are never fetched, so pruning would silently drop them.
      if (!widget.forGuardian) {
        _selectedTags.removeWhere((t) => !state.tagOptions.contains(t));
        _selectedStatuses
            .removeWhere((s) => !_approvalStatusOptions.contains(s));
      }
      _selectedActivityTypes
          .removeWhere((t) => !state.activityTypeOptions.contains(t));
    });
  }

  /// Sections rendered, in order. The guardian persona gets Activity Type only.
  List<String> get _sections => widget.forGuardian
      ? const <String>['Activity Type']
      : const <String>['Tags', 'Activity Type', 'Status'];

  void _apply() {
    Navigator.pop<Map<String, List<String>>>(context, {
      'Tags': List<String>.from(_selectedTags),
      'Activity Type': List<String>.from(_selectedActivityTypes),
      'Status': List<String>.from(_selectedStatuses),
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivityFilterCubit>(
      create: (_) => serviceLocator<ActivityFilterCubit>()
        ..loadMetadata(
          schoolCode: widget.schoolCode,
          forGuardian: widget.forGuardian,
        ),
      child: BlocConsumer<ActivityFilterCubit, ActivityFilterState>(
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
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ResponsiveHelper responsive,
    ActivityFilterState state,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
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
    final sections = _sections;
    if (state.isLoading) {
      final placeholders = sections
          .map(
            (label) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                const ShimmerLoader(height: 40),
              ],
            ),
          )
          .toList();
      return _buildSectionsLayout(placeholders);
    }

    if (state.status == ActivityFilterStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load filter options.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    context.read<ActivityFilterCubit>().loadMetadata(
                      schoolCode: widget.schoolCode,
                      forGuardian: widget.forGuardian,
                    ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSectionsLayout(
      sections.map((label) => _buildSection(label, state)).toList(),
    );
  }

  Widget _buildSection(String label, ActivityFilterState state) {
    switch (label) {
      case 'Tags':
        return CustomMultiSelectDropdown(
          label: 'Tags',
          hintText: 'Select tags',
          items: state.tagOptions,
          selectedItems: _selectedTags,
          labelBottomSpacing: 4,
          onChanged: (values) {
            setState(() => _selectedTags = List<String>.from(values));
          },
        );
      case 'Status':
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
      default:
        return CustomMultiSelectDropdown(
          label: 'Activity Type',
          hintText: 'Select activity',
          items: state.activityTypeOptions,
          selectedItems: _selectedActivityTypes,
          labelBottomSpacing: 4,
          onChanged: (values) {
            setState(() => _selectedActivityTypes = List<String>.from(values));
          },
        );
    }
  }

  /// Two-per-row grid for the staff/admin filter set; a single full-width
  /// dropdown when only one filter is offered (guardian persona), where a
  /// half-width grid cell would leave a lopsided gap.
  Widget _buildSectionsLayout(List<Widget> tiles) {
    if (tiles.length == 1) {
      return ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: tiles,
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) => tiles[index],
    );
  }
}
