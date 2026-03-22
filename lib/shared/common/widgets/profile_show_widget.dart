import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/string_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';

class DocumentImageWidget extends StatefulWidget {
  final String fileUuid;
  final String? name;
  /// Optional staff code for attendance status dot.
  final String? staffCode;

  /// Optional student code for attendance status dot.
  final String? studentCode;
  final double size;
  final String? placeholderAsset;
  final BoxShape shape;
  final BoxFit fit;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final double? fontSize;
  final Color? statusColor; // optional small status dot color

  const DocumentImageWidget({
    Key? key,
    required this.fileUuid,
    this.name,
    this.staffCode,
    this.studentCode,
    this.size = 50.0,
    this.placeholderAsset,
    this.shape = BoxShape.circle,
    this.fit = BoxFit.cover,
    this.onTap,
    this.borderRadius,
    this.errorWidget,
    this.fontSize,
    this.statusColor,
  }) : super(key: key);

  @override
  State<DocumentImageWidget> createState() => _DocumentImageWidgetState();
}

class _DocumentImageWidgetState extends State<DocumentImageWidget> {
  Color? _avatarColor;
  Color? _statusDotColor;
  String? _statusLabel; // SIGNED_IN / ABSENT / null
  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    _avatarColor = _pickStableProfileAvatarColor(
      widget.name?.trim().isNotEmpty == true ? widget.name!.trim() : widget.fileUuid,
    );
    _loadAttendanceStatusIfNeeded();
  }

  @override
  void didUpdateWidget(DocumentImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name || oldWidget.fileUuid != widget.fileUuid) {
      _avatarColor = _pickStableProfileAvatarColor(
        widget.name?.trim().isNotEmpty == true ? widget.name!.trim() : widget.fileUuid,
      );
    }

    if (oldWidget.staffCode != widget.staffCode ||
        oldWidget.studentCode != widget.studentCode) {
      _loadAttendanceStatusIfNeeded();
    }
  }

  Future<void> _loadAttendanceStatusIfNeeded() async {
    // Only one of staffCode / studentCode is expected; if both null, do nothing.
    final staffCode = widget.staffCode;
    final studentCode = widget.studentCode;
    if ((staffCode == null || staffCode.isEmpty) &&
        (studentCode == null || studentCode.isEmpty)) {
      setState(() {
        _statusDotColor = null;
        _statusLabel = null;
      });
      return;
    }

    if (_isLoadingStatus) return;
    _isLoadingStatus = true;

    try {
      String? status;
      if (staffCode != null && staffCode.isNotEmpty) {
        final useCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
        status = await useCase(staffCode: staffCode);
      } else if (studentCode != null && studentCode.isNotEmpty) {
        final useCase = serviceLocator<GetStudentTodaySignInStatusUseCase>();
        status = await useCase(studentCode: studentCode);
      }

      if (!mounted) return;

      // Normalize status to upper-case for comparison.
      final normalized = status?.toUpperCase();
      Color? color;
      String? label;
      if (normalized == 'SIGNED_IN') {
        color = Colors.green;
        label = 'Signed in';
      } else if (normalized == 'ABSENT') {
        color = Colors.red;
        label = 'Absent';
      } else {
        color = null;
        label = null;
      }

      setState(() {
        // For staff/student codes we rely only on API status.
        // If API doesn't return a recognized status, hide the dot.
        _statusDotColor = color;
        _statusLabel = label;
      });
    } catch (_) {
      if (!mounted) return;
      // On error, hide the API-driven status dot so we don't show stale data.
      setState(() {
        _statusDotColor = null;
        _statusLabel = null;
      });
    } finally {
      _isLoadingStatus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: (widget.name != null && widget.name!.isNotEmpty)
          ? _buildAvatarWithStatus(_buildInitialsAvatar())
          : _buildAvatarWithStatus(_buildPlaceholder()),
    );
  }

  Widget _buildImageContainer({required Widget child}) {
    if (widget.shape == BoxShape.circle) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: child,
        ),
      );
    } else {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          child: child,
        ),
      );
    }
  }

  Widget _buildAvatarWithStatus(Widget avatar) {
    final dotColor = _statusDotColor ?? widget.statusColor;
    if (dotColor == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 2,
          top: 2,
          child: Tooltip(
            message: _statusTooltipMessage(),
            waitDuration: const Duration(milliseconds: 100),
            showDuration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
            child: Container(
              width: widget.size * 0.22,
              height: widget.size * 0.22,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _statusTooltipMessage() {
    if (_statusLabel != null) {
      // Prefix with "Staff"/"Student" when we know which one it is.
      if (widget.staffCode != null && widget.staffCode!.isNotEmpty) {
        return 'Staff is ${_statusLabel!.toLowerCase()}';
      }
      if (widget.studentCode != null && widget.studentCode!.isNotEmpty) {
        return 'Student is ${_statusLabel!.toLowerCase()}';
      }
      return _statusLabel!;
    }
    return 'Status';
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      backgroundColor: _avatarColor ?? _pickStableProfileAvatarColor(widget.name?.trim().isNotEmpty == true ? widget.name!.trim() : widget.fileUuid),
      radius: widget.size / 2,
      child: Text(
        StringUtils.getInitials(widget.name!),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: widget.fontSize,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final placeholder = widget.errorWidget ??
        (widget.placeholderAsset != null
            ? Image.asset(
                widget.placeholderAsset!,
                width: widget.size,
                height: widget.size,
                fit: widget.fit,
              )
            : CircleAvatar(
                radius: widget.size / 2,
                backgroundImage: const AssetImage(MediaRes.userImageMale),
              ));

    // Fixed: Improved null safety checks
    if (widget.name == null ||
        widget.name!.isEmpty ||
        widget.fileUuid.isNotEmpty) {
      return _buildImageContainer(child: placeholder);
    } else {
      return CircleAvatar(
        backgroundColor: _avatarColor ?? _pickStableProfileAvatarColor(widget.name?.trim().isNotEmpty == true ? widget.name!.trim() : widget.fileUuid),
        radius: widget.size / 2,
        child: Text(
          StringUtils.getInitials(widget.name!),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: widget.fontSize,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.rectangle
              ? (widget.borderRadius ?? BorderRadius.circular(8))
              : null,
        ),
      ),
    );
  }
}

Color _pickStableProfileAvatarColor(String seed) {
  if (AppColors.profileAvatarColors.isEmpty) return AppColors.primaryColor;
  if (seed.isEmpty) seed = 'default';
  final int index = seed.hashCode.abs() % AppColors.profileAvatarColors.length;
  return AppColors.profileAvatarColors[index];
}
