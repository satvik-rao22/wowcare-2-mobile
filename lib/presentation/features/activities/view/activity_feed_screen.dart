import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/core/util/school_switch_events.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/presentation/features/activities/view/activity_custom_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_student_selection.dart';
import 'package:wowcare/presentation/features/activities/widgets/school_cloud_image_uploader_dialog.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
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

  /// When false, hide add / edit / delete (from [DAILY_ACTIVITY] `write` permission).
  final bool allowActivityWrite;

  static const String routeName = '/activityFeed';

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with TickerProviderStateMixin, SchoolSwitchReloadMixin {
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

      final storage = serviceLocator<StorageService>();
      final staffCode =
          (await storage.getString(StorageKeys.staffCode))?.trim() ?? '';
      final userCode =
          (await storage.getString(StorageKeys.userCode))?.trim() ?? '';
      // Mirrors My Day's `_effectiveStaffCode` fallback.
      final effectiveCode = staffCode.isNotEmpty ? staffCode : userCode;
      if (effectiveCode.isEmpty) return;

      final status = await serviceLocator<GetStaffTodaySignInStatusUseCase>()(
        staffCode: effectiveCode,
      );
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
    final screenWidth = MediaQuery.of(context).size.width;

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
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: const Text(
                'Please sign in to create an activity.',
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: 12,
                ),
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
                                final isTablet =
                                    MediaQuery.of(context).size.width >= 600;
                                final isLargeTablet =
                                    MediaQuery.of(context).size.width >= 900;
                                final iconSize = isLargeTablet
                                    ? 46.0
                                    : isTablet
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        settings: const RouteSettings(
                                          name:
                                              CoreUtils.chooseActivityRouteName,
                                        ),
                                        builder: (_) => ChooseActivity(
                                          selectedStudents:
                                              widget.studentName != null
                                              ? [
                                                  Map<String, dynamic>.from(
                                                    widget.studentName!,
                                                  ),
                                                ]
                                              : <Map<String, dynamic>>[],
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        settings: const RouteSettings(
                                          name: CoreUtils
                                              .activityStudentSelectionRouteName,
                                        ),
                                        builder: (_) =>
                                            ActivityStudentSelection(),
                                      ),
                                    );
                                  }
                                },
                                isTablet:
                                    MediaQuery.of(context).size.width >= 600,
                                isLargeTablet:
                                    MediaQuery.of(context).size.width >= 900,
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
                        ),
                        ActivityCustomTab(
                          fromStudentProfile: widget.fromStudentProfile,
                          studentName: widget.studentName?['name']?.toString(),
                          studentProfile: widget.fromStudentProfile
                              ? widget.studentName
                              : null,
                          isNotParent: true,
                          allowActivityWrite: allowWrite,
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
                        ),
                        ActivityCustomTab(
                          isNotParent: false,
                          allowActivityWrite: allowWrite,
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
      color: Colors.transparent,
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
            style: TextStyle(
              color: isSelected ? AppColors.themeColor : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
