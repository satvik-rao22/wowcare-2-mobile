import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_durations.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/multi_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/segmented_control.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/cubit/attendance_range_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/day_picker_sheet.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/loading_more_row.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/range_row.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/range_strip.dart';

/// 4f. A range of days instead of one.
///
/// The list stops offering sign in keys and becomes two totals per person,
/// Attended Time and Attended Days, both of which come back on the range call
/// the app already makes. It pages as it is scrolled.
class AttendanceRangePage extends StatelessWidget {
  const AttendanceRangePage({
    required this.range,
    required this.today,
    super.key,
  });

  final DateRange range;

  /// The school's own day, for the pickers.
  final DateTime today;

  @override
  Widget build(BuildContext context) => BlocProvider<AttendanceRangeCubit>(
    create: (_) {
      final cubit = redesignLocator<AttendanceRangeCubit>(param1: range);
      unawaited(cubit.load());
      return cubit;
    },
    child: _RangeView(today: today),
  );
}

class _RangeView extends StatefulWidget {
  const _RangeView({required this.today});

  final DateTime today;

  @override
  State<_RangeView> createState() => _RangeViewState();
}

class _RangeViewState extends State<_RangeView> {
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  AttendanceRangeCubit get _cubit => context.read<AttendanceRangeCubit>();

  /// The next page is asked for before the last row is reached, so the list
  /// grows under the thumb rather than stopping at the foot.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.offset;
    if (remaining <= AttendanceSizes.pageTriggerInset) {
      unawaited(_cubit.loadMore());
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      if (!mounted) return;
      unawaited(_cubit.search(query));
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceRangeCubit, AttendanceRangeState>(
        builder: (context, state) => ScreenScaffold(
          header: state.isSearching ? _searchHeader() : _titleHeader(state),
          bodyPadding: EdgeInsets.zero,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: AttendanceSizes.switchMargin,
                child: SegmentedControl(
                  segments: const <String>[
                    AttendanceStrings.studentsSegment,
                    AttendanceStrings.staffSegment,
                  ],
                  sublabels: <String>[
                    AttendanceStrings.inRangeCount(
                      state.audience.isStudents ? state.totalElements : 0,
                    ),
                    AttendanceStrings.inRangeCount(
                      state.audience.isStudents ? 0 : state.totalElements,
                    ),
                  ],
                  index: state.audience.index,
                  onChanged: (index) => unawaited(
                    _cubit.setAudience(AttendanceAudience.values[index]),
                  ),
                ),
              ),
              Padding(
                padding: AttendanceSizes.stripMargin,
                child: RangeStrip(
                  label: AttendanceFormats.rangeLabel(state.range),
                  onChange: () => unawaited(_changeRange(state)),
                  onClearAll: () => unawaited(_cubit.clearAll()),
                ),
              ),
              Expanded(child: _body(state)),
            ],
          ),
        ),
      );

  Widget _titleHeader(AttendanceRangeState state) => AppHeaderBar(
    title: AppStrings.attendance,
    leading: BackKey(onTap: () => context.pop()),
    actions: <Widget>[
      IconKey(
        icon: AppIcons.search,
        semanticLabel: AttendanceStrings.searchKey,
        onTap: _cubit.openSearch,
      ),
      IconKey(
        icon: AppIcons.filter,
        semanticLabel: AttendanceStrings.rangeFilterTitle,
        badgeCount: state.classrooms.length,
        onTap: () => unawaited(_openFilter(state)),
      ),
    ],
  );

  Widget _searchHeader() => Padding(
    padding: AppSizes.headerBarPad,
    child: Row(
      spacing: AppSizes.headerGap,
      children: <Widget>[
        Expanded(
          child: SearchField(
            autofocus: true,
            hintText: AttendanceStrings.searchHint,
            onChanged: _onSearchChanged,
          ),
        ),
        TextLink(
          label: AppStrings.cancel,
          onTap: () => unawaited(_cubit.closeSearch()),
        ),
      ],
    ),
  );

  Widget _body(AttendanceRangeState state) {
    if (state.isLoading) return const LoadingState();
    if (state.isFailed) {
      return Center(
        child: ErrorState(
          message: AttendanceStrings.loadError,
          onRetry: () => unawaited(_cubit.load()),
        ),
      );
    }
    if (state.isEmpty) {
      return Center(
        child: EmptyState(
          icon: AppIcons.calendar,
          title: AttendanceStrings.rangeEmptyTitle,
          subtitle: AttendanceStrings.rangeEmptyBody,
          actionLabel: state.isNarrowed ? AppStrings.clearAll : null,
          onAction: state.isNarrowed
              ? () => unawaited(_cubit.clearAll())
              : null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cubit.refresh,
      child: ListView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: AttendanceSizes.rangeListPad,
        children: <Widget>[
          for (final entry in state.entries)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AttendanceSizes.rangeListGap,
              ),
              child: RangeRow(
                entry: entry,
                isExpanded: state.expandedId == entry.id,
                onTap: () => _cubit.toggleExpanded(entry.id),
                onView: () => unawaited(_view(entry)),
              ),
            ),
          if (state.hasMore) const LoadingMoreRow(),
        ],
      ),
    );
  }

  Future<void> _changeRange(AttendanceRangeState state) async {
    final chosen = await DayPickerSheet.show(
      context,
      today: widget.today,
      day: widget.today,
      range: state.range,
    );
    if (chosen == null || !mounted) return;

    if (chosen.choice == DayChoice.range && chosen.range != null) {
      await _cubit.setRange(chosen.range!);
      return;
    }
    // A single day belongs to the day list, not to a range of one.
    if (mounted) context.pop();
  }

  Future<void> _openFilter(AttendanceRangeState state) async {
    final chosen = await MultiSelectSheet.show<String>(
      context,
      title: AttendanceStrings.rangeFilterTitle,
      subtitle: AttendanceStrings.rangeFilterSubtitle,
      options: <SelectOption<String>>[
        for (final name in state.classroomOptions)
          SelectOption<String>(value: name, label: name),
      ],
      selected: state.classrooms,
    );
    if (chosen != null) await _cubit.setClassrooms(chosen);
  }

  /// The two totals are a summary; the record behind them is the person's own
  /// screen, which is where a range row goes when it is opened.
  Future<void> _view(RangeEntry entry) => context.push<void>(
    entry.audience.isStudents
        ? AppRoutes.student(entry.id)
        : AppRoutes.staffMember(entry.id),
  );
}
