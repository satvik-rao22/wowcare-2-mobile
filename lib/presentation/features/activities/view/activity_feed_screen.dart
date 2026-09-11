import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/core/utils/attendance_events.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/tab_visibility_events.dart';
import 'package:wowcare/presentation/features/activities/view/activity_custom_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_student_selection.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_screen_cubit.dart';
import 'package:wowcare/presentation/features/activities/widgets/school_cloud_image_uploader_dialog.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/activities/model/activity_route_args.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'choose_activity.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.allowActivityWrite = true,
    this.highlightCode,
    this.highlightDate,
    this.highlightClassroomCode,
    this.deepLinkStudentCode,
    this.initialTab,
    this.initialActivityTypes,
    this.initialClassrooms,
    this.resetKey,
  });

  final bool fromStudentProfile;
  final Map<String, dynamic>? studentName;

  /// Activity code from a notification deep-link, forwarded to the Daily tab.
  final String? highlightCode;

  /// Date of the deep-linked activity, forwarded so the Daily tab opens on it.
  final DateTime? highlightDate;

  /// Classroom of the deep-linked activity, forwarded so the Daily tab opens on
  /// the room containing the card (the feed loads one classroom at a time).
  final String? highlightClassroomCode;

  /// The child a notification deep-link is about, forwarded to the GUARDIAN
  /// Daily tab — for a parent the feed is scoped to a child, not a classroom.
  /// See `ActivityDailyTab.deepLinkStudentCode` for why the URL carries it
  /// rather than relying on `ParentChildCubit` alone.
  final String? deepLinkStudentCode;

  /// When false, hide add / edit / delete (from [DAILY_ACTIVITY] `write` permission).
  final bool allowActivityWrite;

  /// The initial tab to show (0 for Daily, 1 for Custom).
  final int? initialTab;

  /// Pre-selected activity types to pass to the Custom tab.
  final List<String>? initialActivityTypes;

  /// Pre-selected classrooms to pass to the Custom tab (e.g., ['all']).
  final List<String>? initialClassrooms;

  /// Used to force state reset in didUpdateWidget when navigating repeatedly.
  final String? resetKey;

  static const String routeName = '/activityFeed';

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with
        TickerProviderStateMixin,
        SchoolSwitchReloadMixin,
        TabBecameVisibleMixin {
  // Activity Feed is branch index 2 in app_router.dart's shell.
  @override
  int get tabBranchIndex => 2;

  @override
  void onTabBecameVisible() {
    if (!mounted) return;
    // Same subtree-recreate trick as onSchoolSwitched() below, triggered by
    // switching back to this tab instead of a school/persona change.
    setState(() => _contextReloadEpoch++);
  }

  late TabController _tabController;
  final ScrollController _dailyScrollController = ScrollController();
  final ScrollController _customScrollController = ScrollController();

  // Bumped on a school OR persona switch to re-key (recreate) the tab
  // content below — this branch screen is kept alive in the shell's
  // IndexedStack across both switch kinds and never re-inits on its own, so
  // without this the activity feed kept showing the previous school/
  // persona's cached activities until the user manually navigated away and
  // back.
  int _contextReloadEpoch = 0;

  @override
  void onSchoolSwitched() {
    if (!mounted) return;
    setState(() => _contextReloadEpoch++);
  }

  /// Whether the STAFF persona has signed in for today. Defaults to true so the
  /// add button is never blocked for other personas, nor while the status is
  /// still loading (only a confirmed "not signed in" disables it).
  bool _staffSignedInToday = true;

  @override
  void didUpdateWidget(covariant ActivityFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool forceReset =
        widget.resetKey != oldWidget.resetKey && widget.resetKey != null;
    if (forceReset ||
        (widget.initialTab != oldWidget.initialTab &&
            widget.initialTab != null)) {
      final int initialIndex = widget.initialTab == 1 ? 1 : 0;
      if (_tabController.index != initialIndex) {
        _tabController.animateTo(initialIndex);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final int initialIndex = widget.initialTab == 1 ? 1 : 0;
    _tabController = TabController(
      initialIndex: initialIndex,
      length: 2,
      vsync: this,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    // RoleCubit lives above this screen, so read it after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStaffSignInStatus();
    });
    // This screen is kept alive in the bottom nav's IndexedStack, so initState
    // only runs once. Re-check the sign-in status whenever ANY attendance
    // mutation fires (sign in/out from this or any other screen) so the add
    // button reflects the latest status without needing an app restart.
    AttendanceEvents.tick.addListener(_loadStaffSignInStatus);
  }

  /// Staff must be signed in before they can record activities. Resolves the
  /// current staff member's today status (`SIGNED_IN` / `SIGNED_OUT` / `ABSENT`)
  /// from the same use case the My Day card uses, so both surfaces agree.
  ///
  /// Staff persona ONLY — admins (and parents) are never gated on attendance.
  Future<void> _loadStaffSignInStatus() async {
    try {
      final role = context.read<RoleCubit>();
      if (!role.isStaff) return;

      final status = await context
          .read<ActivityFeedScreenCubit>()
          .getEffectiveStaffTodaySignInStatus();
      if (!mounted) return;
      setState(() {
        _staffSignedInToday = status?.toUpperCase() == 'SIGNED_IN';
      });
    } catch (_) {
      // Best-effort: on failure leave the button enabled rather than locking
      // staff out of activity creation because a status check errored.
    }
  }

  /// Black tooltip anchored above the add button, matching the disabled-tile
  /// tooltip used on the Choose Activity grid.
  void _showSignInRequiredTooltip(BuildContext anchorContext) {
    final renderObject = anchorContext.findRenderObject();
    if (renderObject is! RenderBox) return;
    final position = renderObject.localToGlobal(Offset.zero);
    final screenWidth = ResponsiveHelper(context).screenWidth;

    final maxWidth = (screenWidth - 16).clamp(160.0, 320.0);
    // Anchor the tooltip's RIGHT edge to the button's right edge, so it sits
    // directly under the + and grows leftward. Positioning by `left` would not
    // work: the box shrinks to fit its text, so a left offset computed from
    // maxWidth would leave it floating well to the left of the button.
    final right = (screenWidth - (position.dx + renderObject.size.width)).clamp(
      8.0,
      screenWidth - 8.0,
    );

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: position.dy + renderObject.size.height + 8,
        right: right,
        child: Material(
          color: AppColors.transparentColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.activityTooltipBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: const Text(
                'Please sign in to create an activity.',
                softWrap: true,
                style: AppTextStyles.activityTooltipText,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    AttendanceEvents.tick.removeListener(_loadStaffSignInStatus);
    _tabController.dispose();
    _dailyScrollController.dispose();
    _customScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final role = context.watch<RoleCubit>();
    final staffLike = !role.isParent;
    final allowWrite =
        widget.allowActivityWrite &&
        ModuleAccess.mayWrite(role, AppAccessModules.dailyActivity);
    // Staff persona ONLY (role.isStaff excludes admins): activity creation is
    // gated on having signed in for the day.
    final addBlockedForSignIn = role.isStaff && !_staffSignedInToday;

    return KeyedSubtree(
      key: ValueKey('activity_feed_$_contextReloadEpoch'),
      child: GlobalScaffold(
        //hasBackButton: true,
        showCustomNavigationBar: true,
        isParent: role.isParent,
        body: staffLike
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        height: 50,
                        child: Row(
                          children: [
                            _buildTabToggleButton(
                              isSelected: _tabController.index == 0,
                              onPressed: () => _tabController.animateTo(0),
                              text: 'Daily',
                            ),
                            _buildTabToggleButton(
                              isSelected: _tabController.index == 1,
                              onPressed: () => _tabController.animateTo(1),
                              text: 'Custom',
                            ),
                          ],
                        ),
                      ),
                      if (allowWrite)
                        Row(
                          children: [
                            Builder(
                              builder: (_) {
                                final iconSize = responsive.isWide
                                    ? 46.0
                                    : responsive.isTabletCompact
                                    ? 36.0
                                    : 30.0;
                                return GestureDetector(
                                  onTap: () =>
                                      showSchoolCloudImageUploaderDialog(
                                        context,
                                      ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SvgPicture.asset(
                                      MediaRes.uploadCloudIcon,
                                      width: iconSize,
                                      height: iconSize,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 2),
                            Builder(
                              builder: (btnContext) => GradientAddButton(
                                isDisabled: addBlockedForSignIn,
                                onTap: () {
                                  // Staff who haven't signed in today: explain
                                  // instead of navigating.
                                  if (addBlockedForSignIn) {
                                    _showSignInRequiredTooltip(btnContext);
                                    return;
                                  }
                                  if (widget.fromStudentProfile) {
                                    context.push(
                                      ChooseActivity.routeName,
                                      extra: ChooseActivityArgs(
                                        selectedStudents:
                                            widget.studentName != null
                                            ? [
                                                Map<String, dynamic>.from(
                                                  widget.studentName!,
                                                ),
                                              ]
                                            : <Map<String, dynamic>>[],
                                      ),
                                    );
                                  } else {
                                    context.push(
                                      ActivityStudentSelection.routeName,
                                    );
                                  }
                                },
                                isTablet: responsive.isTabletCompact,
                                isLargeTablet: responsive.isWide,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                    ],
                  ),
                  Flexible(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ActivityDailyTab(
                          fromStudentProfile: widget.fromStudentProfile,
                          studentName: widget.studentName?['name']?.toString(),
                          studentProfile: widget.fromStudentProfile
                              ? widget.studentName
                              : null,
                          isNotParent: true,
                          allowActivityWrite: allowWrite,
                          highlightCode: widget.highlightCode,
                          highlightDate: widget.highlightDate,
                          highlightClassroomCode: widget.highlightClassroomCode,
                          onRefreshStaffSignInStatus: _loadStaffSignInStatus,
                        ),
                        ActivityCustomTab(
                          fromStudentProfile: widget.fromStudentProfile,
                          studentName: widget.studentName?['name']?.toString(),
                          studentProfile: widget.fromStudentProfile
                              ? widget.studentName
                              : null,
                          isNotParent: true,
                          allowActivityWrite: allowWrite,
                          initialActivityTypes: widget.initialActivityTypes,
                          initialClassrooms: widget.initialClassrooms,
                          resetKey: widget.resetKey,
                          onRefreshStaffSignInStatus: _loadStaffSignInStatus,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        _buildTabToggleButton(
                          isSelected: _tabController.index == 0,
                          onPressed: () => _tabController.animateTo(0),
                          text: 'Daily',
                        ),
                        _buildTabToggleButton(
                          isSelected: _tabController.index == 1,
                          onPressed: () => _tabController.animateTo(1),
                          text: 'Custom',
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ActivityDailyTab(
                          isNotParent: false,
                          allowActivityWrite: allowWrite,
                          highlightCode: widget.highlightCode,
                          highlightDate: widget.highlightDate,
                          deepLinkStudentCode: widget.deepLinkStudentCode,
                        ),
                        ActivityCustomTab(
                          isNotParent: false,
                          allowActivityWrite: allowWrite,
                          initialActivityTypes: widget.initialActivityTypes,
                          initialClassrooms: widget.initialClassrooms,
                          resetKey: widget.resetKey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabToggleButton({
    required bool isSelected,
    required VoidCallback onPressed,
    required String text,
  }) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    bottom: BorderSide(color: AppColors.themeColor, width: 2),
                  )
                : null,
          ),
          child: Text(
            text,
            style: AppTextStyles.activityTabToggleLabel(isSelected: isSelected),
          ),
        ),
      ),
    );
  }
}
