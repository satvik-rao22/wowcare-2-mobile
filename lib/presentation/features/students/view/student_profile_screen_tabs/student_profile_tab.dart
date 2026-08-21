import 'package:flutter/material.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_tab_cards/student_about_tab_card.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

import '../../../../../app/theme/colors.dart';
import '../student_profile_tab_cards/student_family_tab_card.dart';
import '../student_profile_tab_cards/student_pickup_tab_card.dart';

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({
    super.key,
    this.initialTabIndex = 0,
    required this.scrollController,
    required this.name,
    required this.classroom,
    required this.tags,
    required this.schedule,
    required this.sibling,
    this.studentCode,
    this.onProfileChanged,
  });

  final int initialTabIndex;
  final ScrollController scrollController;
  final String name;
  final String classroom;
  final List<String> tags;
  final List<String> schedule;
  final Map<String, dynamic> sibling;
  final String? studentCode;
  final ValueChanged<StudentProfileModel>? onProfileChanged;

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _aboutScrollController = ScrollController();
  final ScrollController _familyScrollController = ScrollController();
  final ScrollController _pickupScrollController = ScrollController();
  late Future<StudentProfileModel?> _profileFuture;
  late final CacheManager _cacheManager;

  /// School code used by the Family tab when the student profile failed to
  /// load (so guardian actions still target the active school). Best-effort
  /// from storage; the profile's own schoolCode is preferred when available.
  String _fallbackSchoolCode = '';

  static String _studentProfileCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'profile',
        identifier: studentCode.trim(),
      );

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });
    _cacheManager = CacheManager(serviceLocator<StorageService>());
    _loadFallbackSchoolCode();

    // Fetch student profile if studentCode is provided
    if (widget.studentCode != null && widget.studentCode!.isNotEmpty) {
      final future = _loadProfileCached(widget.studentCode!);
      _profileFuture = future;
      future
          .then((profile) {
            if (!mounted) return;
            if (profile != null) widget.onProfileChanged?.call(profile);
          })
          .catchError((Object error) {
            // About tab renders the inline error; also surface it to the user.
            _showProfileErrorBanner(error);
          });
    } else {
      _profileFuture = Future<StudentProfileModel?>.value(null);
    }
  }

  Future<void> _loadFallbackSchoolCode() async {
    try {
      final code = await serviceLocator<StorageService>().getString(
        StorageKeys.schoolCode,
      );
      if (!mounted) return;
      if (code != null && code.trim().isNotEmpty) {
        setState(() => _fallbackSchoolCode = code.trim());
      }
    } catch (_) {
      // Best-effort only; Family tab tolerates an empty school code.
    }
  }

  /// Surfaces a failed student-profile fetch through the shared error banner
  /// ([CoreUtils]) so the server message is visible, while the Family and
  /// Pickup tabs keep working independently.
  void _showProfileErrorBanner(Object error) {
    if (!mounted) return;
    CoreUtils.logApiError(
      ApiErrorHandler.extractErrorMessage(error),
      showOnScreen: true,
      context: context,
    );
  }

  Future<void> _refreshProfile() async {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) return;
    // Create new future and update state to force FutureBuilder rebuild
    final newFuture = _loadProfileFresh(code);
    setState(() {
      _profileFuture = newFuture;
    });
    try {
      // Wait for the future to complete to ensure data is loaded
      final refreshed = await newFuture;
      if (refreshed != null) widget.onProfileChanged?.call(refreshed);
    } catch (error) {
      // About tab renders the inline error; also surface it to the user.
      _showProfileErrorBanner(error);
    }
  }

  Future<StudentProfileModel?> _loadProfileCached(String studentCode) async {
    final cacheKey = _studentProfileCacheKey(studentCode);
    try {
      final payload = await _cacheManager.loadCache(cacheKey);
      if (payload != null) {
        final model = StudentProfileModel.fromJson(payload);
        // Stale-while-revalidate: cached data is returned immediately below,
        // but the background refresh's result was previously only used to
        // show an error banner on failure — a successful fresh fetch was
        // silently dropped, so anything only present in the fresh response
        // (e.g. classroomCode, added to the cached shape after some
        // profiles were already cached under the old format) would never
        // reach the header/callers until the cache separately expired.
        // ignore: unawaited_futures
        _loadProfileFresh(studentCode)
            .then((refreshed) {
              if (!mounted || refreshed == null) return;
              widget.onProfileChanged?.call(refreshed);
            })
            .catchError((Object error) {
              _showProfileErrorBanner(error);
            });
        return model;
      }
    } catch (_) {
      // Fall back to remote below.
    }
    return _loadProfileFresh(studentCode);
  }

  Future<StudentProfileModel?> _loadProfileFresh(String studentCode) async {
    final dataSource = serviceLocator<StudentRemoteDataSource>();
    final model = await dataSource.getStudentProfile(studentCode);
    await _cacheManager.saveCache(
      _studentProfileCacheKey(studentCode),
      model.toJson(),
    );
    return model;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aboutScrollController.dispose();
    _familyScrollController.dispose();
    _pickupScrollController.dispose();
    super.dispose();
  }

  Tab _buildTab({required String label, required Color color}) {
    return Tab(
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(child: Text(label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, 0),
          child: TabBar(
            controller: _tabController,
            dividerHeight: 0,
            indicator: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(
                color: AppColors.classroomStudentTabColor.withValues(alpha: 1),
              ),
            ),
            labelStyle: TextTheme.of(
              context,
            ).titleSmall!.copyWith(color: AppColors.primaryColor, fontSize: 15),
            unselectedLabelStyle: TextTheme.of(context).titleSmall!.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            labelPadding: const EdgeInsets.all(0),
            indicatorPadding: _tabController.index == 0
                ? const EdgeInsets.only(right: 4)
                : _tabController.index == 1
                ? const EdgeInsets.symmetric(horizontal: 2)
                : const EdgeInsets.only(left: 4),
            splashFactory: NoSplash.splashFactory,
            tabs: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildTab(
                  label: 'About',
                  color: AppColors.classroomStudentTabColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildTab(
                  label: 'Family',
                  color: AppColors.classroomStaffTabColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _buildTab(
                  label: 'Pickup',
                  color: AppColors.classroomNotesTabColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<StudentProfileModel?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final hasCode =
                  widget.studentCode != null && widget.studentCode!.isNotEmpty;
              final isWaiting =
                  hasCode &&
                  snapshot.connectionState == ConnectionState.waiting;

              // Only the About tab depends on the student profile model.
              // Family and Pickup load their own data from studentCode, so a
              // profile fetch failure (e.g. a 500) must NOT block them —
              // build them unconditionally and let the About tab own its
              // loading/error state.
              final Widget aboutChild;
              if (isWaiting) {
                aboutChild = CustomRefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    children: const [StudentProfileInfoShimmer()],
                  ),
                );
              } else if (snapshot.hasError) {
                aboutChild = _buildAboutError(snapshot.error);
              } else if (profile != null) {
                aboutChild = _buildAboutFromProfile(profile);
              } else {
                aboutChild = _buildAboutFromWidget();
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  aboutChild,
                  _buildFamilyTab(profile),
                  _buildPickupTab(profile),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// About tab built from cached/widget data when the profile model is
  /// unavailable (no studentCode or API returned null).
  Widget _buildAboutFromWidget() {
    return StudentAboutTabCard(
      scrollController: _aboutScrollController,
      name: widget.name,
      classroom: widget.classroom,
      tags: widget.tags,
      schedule: widget.schedule,
      sibling: widget.sibling,
      onRefresh: _refreshProfile,
      studentCode: widget.studentCode,
    );
  }

  /// About tab error state. Family and Pickup tabs remain usable; only this
  /// tab reflects the failed profile fetch (the message is also surfaced via
  /// [CoreUtils]).
  Widget _buildAboutError(Object? error) {
    return CustomRefreshIndicator(
      onRefresh: _refreshProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load student profile',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            ApiErrorHandler.extractErrorMessage(error),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _refreshProfile,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  /// About tab built from the loaded [profile] model.
  Widget _buildAboutFromProfile(StudentProfileModel profile) {
    // Derive tags list from profile API (tags[].name)
    final apiTags = (profile.tags)
        .whereType<Map<String, dynamic>>()
        .map((t) => (t['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();

    // Derive schedule short-day list from regularSchedules[].dayOfWeek
    final apiSchedule = (profile.regularSchedules)
        .whereType<Map<String, dynamic>>()
        .map((s) => (s['dayOfWeek'] ?? '').toString().toUpperCase())
        .map(_shortDayLabel)
        .where((d) => d.isNotEmpty)
        .toList();

    // Derive sibling display map from profile API siblings[]
    final siblingNames = <String>[];
    final siblingRelations = <String>[];
    final siblingStatuses = <String>[];
    for (final raw in profile.siblings) {
      if (raw is! Map<String, dynamic>) continue;
      final first = (raw['firstName'] ?? '').toString().trim();
      final last = (raw['lastName'] ?? '').toString().trim();
      final name = ('$first $last').trim();
      if (name.isEmpty) continue;
      siblingNames.add(name);
      siblingRelations.add('Sibling');
      siblingStatuses.add((raw['status'] ?? '').toString().toLowerCase());
    }

    return StudentAboutTabCard(
      scrollController: _aboutScrollController,
      name: profile.fullName.isNotEmpty ? profile.fullName : widget.name,
      classroom: profile.classroom ?? widget.classroom,
      tags: apiTags,
      schedule: apiSchedule,
      sibling: <String, dynamic>{
        'name': siblingNames,
        'relation': siblingRelations,
        'status': siblingStatuses,
      },
      studentProfile: profile,
      onRefresh: _refreshProfile,
      studentCode: profile.code,
    );
  }

  static String _shortDayLabel(String dayOfWeek) {
    switch (dayOfWeek) {
      case 'MONDAY':
        return 'Mon';
      case 'TUESDAY':
        return 'Tue';
      case 'WEDNESDAY':
        return 'Wed';
      case 'THURSDAY':
        return 'Thu';
      case 'FRIDAY':
        return 'Fri';
      case 'SATURDAY':
        return 'Sat';
      case 'SUNDAY':
        return 'Sun';
      default:
        return '';
    }
  }

  /// Family tab — loads its own guardian data from studentCode and never
  /// depends on the About profile fetch succeeding. Prefers the profile's
  /// schoolCode, falling back to the active school from storage.
  Widget _buildFamilyTab(StudentProfileModel? profile) {
    final hasProfileSchool =
        profile != null && profile.schoolCode.trim().isNotEmpty;
    return StudentFamilyTabCard(
      scrollController: _familyScrollController,
      name: (profile != null && profile.fullName.isNotEmpty)
          ? profile.fullName
          : widget.name,
      classroom: profile?.classroom ?? widget.classroom,
      studentCode: profile?.code ?? widget.studentCode,
      schoolCode: hasProfileSchool ? profile.schoolCode : _fallbackSchoolCode,
      onRefresh: _refreshProfile,
    );
  }

  /// Pickup tab — loads its own pickup data from studentCode and never depends
  /// on the About profile fetch succeeding.
  Widget _buildPickupTab(StudentProfileModel? profile) {
    return StudentPickupTabCard(
      scrollController: _pickupScrollController,
      name: (profile != null && profile.fullName.isNotEmpty)
          ? profile.fullName
          : widget.name,
      classroom: profile?.classroom ?? widget.classroom,
      studentCode: profile?.code ?? widget.studentCode,
      onRefresh: _refreshProfile,
    );
  }
}
