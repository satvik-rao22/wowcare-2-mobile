import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
// The following imports depend on backend/bloc not available now. Keeping commented.
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
// import 'package:wowcare/src/documents/presentation/bloc/document_bloc.dart';
// import 'package:wowcare/core/services/injection_container.dart';
// import 'package:wowcare/core/util/typedefs.dart';

// Local fallback typedef since global typedefs are not available here
typedef DataMap = Map<String, dynamic>;

class ClassroomStudentListItem extends StatefulWidget {
  final int studentId;
  final String studentCode;
  final String name;
  final String imageUrl;
  final DataMap icons;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final String studentStatus;
  final String? todayAttendanceStatusRaw;

  /// When the classroom roster is filtered to upcoming students only, show the
  /// amber profile dot even if [studentStatus] from the API is missing or varies.
  final bool forceUpcomingProfileStatusDot;

  const ClassroomStudentListItem({
    super.key,
    this.isSelected = false,
    required this.studentId,
    required this.studentCode,
    required this.onSelectionChanged,
    required this.isSignedIn,
    required this.isAbsent,
    required this.isExpectedToday,
    required this.name,
    required this.imageUrl,
    required this.icons,
    required this.studentStatus,
    this.todayAttendanceStatusRaw,
    this.forceUpcomingProfileStatusDot = false,
  });

  @override
  State<ClassroomStudentListItem> createState() =>
      _ClassroomStudentListItemState();
}

class _ClassroomStudentListItemState extends State<ClassroomStudentListItem> {
  @override
  void initState() {
    super.initState();
    // Backend dependent. Disabled for now; UI uses static placeholder.
    // getStudentProfile();
  }

  // Backend dependent. Disabled for now; UI uses static placeholder.
  // void getStudentProfile() {
  //   DataMap parameters = {
  //     'fileUuid.equals': widget.imageUrl,
  //   };
  //   context.read<DocumentBloc>().add(DownloadDocument(parameters));
  // }

  @override
  Widget build(BuildContext context) {
    final normalizedAttendance = (widget.todayAttendanceStatusRaw ?? '')
        .trim()
        .toUpperCase();
    final hasAttendanceStatus =
        normalizedAttendance == 'SIGNED_IN' || normalizedAttendance == 'ABSENT';
    final shouldGreyOut =
        !widget.isExpectedToday &&
        !widget.isSignedIn &&
        !widget.isAbsent &&
        !hasAttendanceStatus;
    final enrollmentStatus = widget.forceUpcomingProfileStatusDot
        ? 'UPCOMING'
        : widget.studentStatus.trim();
    final Color? attendanceDotColor = normalizedAttendance == 'SIGNED_IN'
        ? Colors.green
        : (normalizedAttendance == 'ABSENT' ? Colors.red : null);
    final String? attendanceTooltip = normalizedAttendance == 'SIGNED_IN'
        ? 'Student is signed in'
        : (normalizedAttendance == 'ABSENT' ? 'Student is absent' : null);
    final rawPhoto = widget.imageUrl.trim();
    final bool looksLikeUrl =
        rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://');
    final String? directUrl = looksLikeUrl ? rawPhoto : null;
    final String? assetCode = (!looksLikeUrl && rawPhoto.isNotEmpty)
        ? rawPhoto
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: shouldGreyOut ? Colors.grey[100] : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: CustomCheckbox(
              borderColor: AppColors.primaryColor.withValues(alpha: 0.2),
              value: widget.isSelected,
              onChanged: widget.onSelectionChanged,
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: shouldGreyOut ? 0.5 : 1,
              child: AbsorbPointer(
                absorbing: shouldGreyOut,
                child: GestureDetector(
                  onTap: () => widget.onSelectionChanged(!widget.isSelected),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          DocumentImageWidget(
                            fileUuid: widget.studentCode.trim().isNotEmpty
                                ? widget.studentCode
                                : widget.studentId.toString(),
                            imageUrl: directUrl,
                            mediaAssetCode: assetCode,
                            name: widget.name,
                            studentCode: widget.studentCode.trim().isNotEmpty
                                ? widget.studentCode.trim()
                                : null,
                            studentEnrollmentStatus: enrollmentStatus,
                            statusColor: attendanceDotColor,
                            statusTooltip: attendanceTooltip,
                            disableAttendanceStatusLookup: true,
                            size: 50,
                          ),
                          if (widget.icons.containsKey('napping'))
                            Positioned(
                              right: 0, // Moved to top right
                              top: 0,
                              child: Tooltip(
                                message: 'Student is currently napping',
                                child: SvgPicture.asset(
                                  // Guard against empty path in assets
                                  MediaRes.napIcon.isNotEmpty
                                      ? MediaRes.napIcon
                                      : MediaRes.sleepIcon,
                                  height: 18,
                                  width: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.name.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => _StudentDetailsDialog(
                  studentCode: widget.studentCode,
                  studentName: widget.name,
                  iconKeys: widget.icons.keys.toList(),
                ),
              );
            },
            child: Row(
              children: widget.icons.entries.map((entry) {
                final String iconPath = entry.value["icon"];
                final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Tooltip(
                    message:
                        entry.value["info"] ?? getDefaultIconDetail(entry.key),
                    child: isSvg
                        ? SvgPicture.asset(iconPath, height: 18)
                        : Image.asset(iconPath, height: 18),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

String getDefaultIconDetail(String key) {
  Map<String, String> details = {
    "photo": "Photo Permission not given by parent",
    "medication": "Student has health concerns",
    "note": "Documents not submitted",
    "allergies": "Observe first aid",
    "dietRestriction": "Observe first aid",
    "napping": "Student is currently napping",
  };

  return details[key] ?? 'Details not available';
}

/// Tap on the row's icon strip opens this dialog. We fetch the student's
/// health record on open so allergies / medications / dietary restrictions
/// are rendered with the actual text from the API instead of a generic label.
class _StudentDetailsDialog extends StatefulWidget {
  const _StudentDetailsDialog({
    required this.studentCode,
    required this.studentName,
    required this.iconKeys,
  });

  final String studentCode;
  final String studentName;
  final List<String> iconKeys;

  @override
  State<_StudentDetailsDialog> createState() => _StudentDetailsDialogState();
}

class _StudentDetailsDialogState extends State<_StudentDetailsDialog> {
  StudentHealthModel? _health;
  bool _loading = true;
  bool _needsHealth = false;

  static const Set<String> _healthBackedKeys = {
    'allergies',
    'medication',
    'dietRestriction',
    'photo',
  };

  @override
  void initState() {
    super.initState();
    final code = widget.studentCode.trim();
    _needsHealth =
        widget.iconKeys.any(_healthBackedKeys.contains) && code.isNotEmpty;
    if (!_needsHealth) {
      _loading = false;
      return;
    }

    // Reopen instantly if we already fetched this student recently.
    final cached = _cachedHealthIfFresh(code);
    if (cached != null) {
      _health = cached;
      _loading = false;
      return;
    }

    // A prefetch (warmed when the roster loaded) may still be in flight —
    // piggy-back on it instead of firing a second network call.
    final inflight = _healthInflight[code];
    if (inflight != null) {
      inflight.then((result) {
        if (!mounted) return;
        setState(() {
          _health = result ?? _cachedHealthIfFresh(code);
          _loading = false;
        });
      });
      return;
    }

    _fetchHealth();
  }

  Future<void> _fetchHealth() async {
    final code = widget.studentCode.trim();
    try {
      final remote = serviceLocator<StudentRemoteDataSource>();
      final result = await remote.getStudentHealth(code: code);
      _healthCache[code] = _HealthCacheEntry(
        fetchedAt: DateTime.now(),
        health: result,
      );
      if (!mounted) return;
      setState(() {
        _health = result;
        _loading = false;
      });
    } catch (_) {
      // Surface a graceful empty state — the row icons themselves already
      // told the user that *something* is on file, so we just can't load the
      // text right now.
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.studentName.trim().isEmpty ? 'Details' : widget.studentName,
        style: const TextStyle(
          fontFamily: 'Manrope',
          color: AppColors.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: PrimaryCircularLoader()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.iconKeys
                  .map(_buildRow)
                  .whereType<Widget>()
                  .toList(),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildRow(String key) {
    final String iconPath;
    final String label;
    final String value;

    switch (key) {
      case 'napping':
        iconPath = 'assets/images/icons/sleep.png';
        label = 'Napping';
        value = 'Currently napping';
        break;
      case 'photo':
        iconPath = MediaRes.cameraIcon;
        label = 'Photo permission';
        value = (_health?.photoPermission == false)
            ? 'Photo permission not granted'
            : 'Photo permission not granted by parent';
        break;
      case 'allergies':
        iconPath = MediaRes.alertIcon;
        label = 'Allergies';
        value = _nonEmpty(_health?.allergy) ?? 'No details on file';
        break;
      case 'medication':
        iconPath = MediaRes.healthIcon;
        label = 'Medication';
        value = _nonEmpty(_health?.medications) ?? 'No details on file';
        break;
      case 'dietRestriction':
        iconPath = MediaRes.foodIcon2;
        label = 'Dietary restrictions';
        value = _nonEmpty(_health?.dietRestrictions) ?? 'No details on file';
        break;
      case 'note':
        iconPath = MediaRes.docsIcon;
        label = 'Notes';
        value = 'See profile for notes';
        break;
      default:
        return null;
    }

    final isSvg = iconPath.toLowerCase().endsWith('.svg');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isSvg
              ? SvgPicture.asset(iconPath, height: 24, width: 24)
              : Image.asset(iconPath, height: 24, width: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xff573353),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: Color(0xff573353),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _nonEmpty(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _HealthCacheEntry {
  const _HealthCacheEntry({required this.fetchedAt, required this.health});
  final DateTime fetchedAt;
  final StudentHealthModel health;
}

const Duration _healthCacheTtl = Duration(minutes: 10);
final Map<String, _HealthCacheEntry> _healthCache =
    <String, _HealthCacheEntry>{};
final Map<String, Future<StudentHealthModel?>> _healthInflight =
    <String, Future<StudentHealthModel?>>{};

StudentHealthModel? _cachedHealthIfFresh(String studentCode) {
  final entry = _healthCache[studentCode];
  if (entry == null) return null;
  if (DateTime.now().difference(entry.fetchedAt) > _healthCacheTtl) {
    _healthCache.remove(studentCode);
    return null;
  }
  return entry.health;
}

/// Drops the cached health row for [studentCode] so the next dialog open
/// re-fetches. Call this after flows that can mutate the student's health
/// record (e.g. returning from the profile screen edit flow).
void invalidateStudentDetailsHealthCache(String studentCode) {
  _healthCache.remove(studentCode.trim());
}

/// Warms the row-icon details cache so the dialog can open instantly. Safe to
/// call eagerly — already-cached + already-in-flight requests are deduped.
/// Errors are swallowed; the dialog falls back to its own fetch on open.
Future<void> prefetchStudentDetailsHealth(String studentCode) async {
  final code = studentCode.trim();
  if (code.isEmpty) return;
  if (_cachedHealthIfFresh(code) != null) return;
  if (_healthInflight.containsKey(code)) return;

  final future = () async {
    try {
      final remote = serviceLocator<StudentRemoteDataSource>();
      final result = await remote.getStudentHealth(code: code);
      _healthCache[code] = _HealthCacheEntry(
        fetchedAt: DateTime.now(),
        health: result,
      );
      return result;
    } catch (_) {
      return null;
    } finally {
      _healthInflight.remove(code);
    }
  }();
  _healthInflight[code] = future;
  await future;
}
