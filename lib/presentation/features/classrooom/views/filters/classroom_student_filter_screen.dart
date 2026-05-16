import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Result applied to [GetStudentClassroomListUseCase] / student-classroom API.
class ClassroomStudentFilterResult {
  const ClassroomStudentFilterResult({
    required this.status,
    required this.tagCodes,
  });

  /// API values, e.g. `ACTIVE`, `UPCOMING`. Empty = no status filter.
  final List<String> status;

  /// Backend tag codes. Empty = no tag filter.
  final List<String> tagCodes;
}

/// Filter UI for classroom Students tab only: **Status** + **Tags**.
/// Matches layout/controls pattern of [StudentFilterScreen].
class ClassroomStudentFilterScreen extends StatefulWidget {
  const ClassroomStudentFilterScreen({
    super.key,
    this.initialStatus = const [],
    this.initialTagCodes = const [],
  });

  /// Initial selection: API status values (`ACTIVE`, `UPCOMING`).
  final List<String> initialStatus;

  /// Initial selection: tag codes from backend.
  final List<String> initialTagCodes;

  @override
  State<ClassroomStudentFilterScreen> createState() =>
      _ClassroomStudentFilterScreenState();
}

class _ClassroomStudentFilterScreenState
    extends State<ClassroomStudentFilterScreen> {
  static const List<String> _statusLabels = ['Active', 'Upcoming'];

  final List<String> _selectedStatus = [];
  final List<String> _selectedTagNames = [];

  List<String> _tagNameOptions = [];

  /// name -> code
  Map<String, String> _nameToCode = {};

  late final GetTagNameCodeMapForSchoolUseCase _tagMapUseCase;
  late final StorageService _storageService;

  bool _loadingTags = true;

  @override
  void initState() {
    super.initState();
    _tagMapUseCase = serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
    _storageService = serviceLocator<StorageService>();

    final initialStatus = widget.initialStatus
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (initialStatus.contains('ACTIVE')) {
      _selectedStatus.add('Active');
    }
    if (initialStatus.contains('UPCOMING')) {
      _selectedStatus.add('Upcoming');
    }

    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _loadingTags = true);
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) {
        if (mounted) setState(() => _loadingTags = false);
        return;
      }

      final map = await _tagMapUseCase(schoolCode: schoolCode);
      final names = map.keys.toList()..sort();

      final initialCodes = widget.initialTagCodes
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      final preselectedNames = <String>[];
      for (final e in map.entries) {
        if (initialCodes.contains(e.value.trim().toUpperCase())) {
          preselectedNames.add(e.key);
        }
      }

      if (!mounted) return;
      setState(() {
        _nameToCode = map;
        _tagNameOptions = names;
        _selectedTagNames
          ..clear()
          ..addAll(preselectedNames);
        _selectedTagNames.removeWhere((n) => !_tagNameOptions.contains(n));
        _loadingTags = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTags = false);
    }
  }

  void _apply() {
    final statusApi = <String>[];
    for (final s in _selectedStatus) {
      if (s == 'Active') {
        statusApi.add('ACTIVE');
      } else if (s == 'Upcoming') {
        statusApi.add('UPCOMING');
      }
    }

    final tagCodes = <String>[];
    for (final name in _selectedTagNames) {
      final code = _nameToCode[name];
      if (code != null && code.trim().isNotEmpty) {
        tagCodes.add(code.trim());
      }
    }

    Navigator.of(context).pop<ClassroomStudentFilterResult>(
      ClassroomStudentFilterResult(status: statusApi, tagCodes: tagCodes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: 'Filter Students',
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
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingTags && _tagNameOptions.isEmpty) {
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
          final labels = ['Status', 'Tags'];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels[index],
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

    const labels = ['Status', 'Tags'];
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
        if (index == 0) {
          return CustomMultiSelectDropdown(
            label: labels[0],
            hintText: 'Select',
            items: _statusLabels,
            selectedItems: List<String>.from(_selectedStatus),
            onChanged: (selectedItems) {
              setState(() {
                _selectedStatus
                  ..clear()
                  ..addAll(
                    selectedItems.isEmpty
                        ? const <String>[]
                        : <String>[selectedItems.last],
                  );
              });
            },
          );
        }
        return CustomMultiSelectDropdown(
          label: labels[1],
          hintText: 'Select',
          items: _tagNameOptions,
          selectedItems: List<String>.from(_selectedTagNames),
          onChanged: (selectedItems) {
            setState(() {
              _selectedTagNames
                ..clear()
                ..addAll(selectedItems);
            });
          },
        );
      },
    );
  }
}
