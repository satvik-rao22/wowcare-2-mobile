import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/activities/util/activity_filter_metadata_cache.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Activity feed filters: **Tags** (school-wide) + **Activity Type** (per classroom).
/// Loads tag name/code map and classroom activity settings with disk cache.
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
  late final GetTagNameCodeMapForSchoolUseCase _tagMapUseCase;
  late final GetClassroomActivitySettingsUseCase _settingsUseCase;
  late final CacheManager _cacheManager;

  List<String> _tagOptions = const [];
  List<String> _activityTypeOptions = const [];

  List<String> _selectedTags = [];
  List<String> _selectedActivityTypes = [];

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tagMapUseCase = serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
    _settingsUseCase = serviceLocator<GetClassroomActivitySettingsUseCase>();
    _cacheManager = CacheManager(serviceLocator<StorageService>());

    final initial = widget.initialFilters ?? const {};
    _selectedTags = List<String>.from(initial['Tags'] ?? const []);
    _selectedActivityTypes =
        List<String>.from(initial['Activity Type'] ?? const []);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMetadata());
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      // Run tag map + classroom activity settings APIs concurrently.
      final tagMapFuture = ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _tagMapUseCase,
        schoolCode: widget.schoolCode,
      );
      final settingsFuture = ActivityFilterMetadataCache.loadClassroomActivitySettings(
        cacheManager: _cacheManager,
        useCase: _settingsUseCase,
        classroomCode: widget.classroomCode,
      );
      final tagMap = await tagMapFuture;
      final settings = await settingsFuture;

      if (!mounted) return;

      final tagNames = tagMap.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final typeNames = settings
          .map((ActivitySetting s) => s.activityTypeName.trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _tagOptions = tagNames;
        _activityTypeOptions = typeNames;
        _selectedTags.removeWhere((t) => !_tagOptions.contains(t));
        _selectedActivityTypes
            .removeWhere((t) => !_activityTypeOptions.contains(t));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _apply() {
    Navigator.pop<Map<String, List<String>>>(context, {
      'Tags': List<String>.from(_selectedTags),
      'Activity Type': List<String>.from(_selectedActivityTypes),
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: 'Filter Activities',
      child: _buildBody(),
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
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
        isLoading: _loading,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: 2,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          final label = index == 0 ? 'Tags' : 'Activity Type';
          return Column(
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
          );
        },
      );
    }

    if (_loadError != null) {
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
                onPressed: _loadMetadata,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 2,
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
            items: _tagOptions,
            selectedItems: _selectedTags,
            onChanged: (values) {
              setState(() => _selectedTags = List<String>.from(values));
            },
          );
        }
        return CustomMultiSelectDropdown(
          label: 'Activity Type',
          hintText: 'Select activity',
          items: _activityTypeOptions,
          selectedItems: _selectedActivityTypes,
          onChanged: (values) {
            setState(() => _selectedActivityTypes = List<String>.from(values));
          },
        );
      },
    );
  }
}
