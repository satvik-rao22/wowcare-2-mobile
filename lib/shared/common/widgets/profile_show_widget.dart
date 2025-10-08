import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/string_utils.dart';
import 'package:shimmer/shimmer.dart';

class DocumentImageWidget extends StatefulWidget {
  final String fileUuid;
  final String? name;
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
  @override
  void initState() {
    super.initState();
    // UI-only: no backend fetch
    _avatarColor = _pickStableProfileAvatarColor(widget.name?.trim().isNotEmpty == true ? widget.name!.trim() : widget.fileUuid);
  }

  @override
  void didUpdateWidget(DocumentImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _avatarColor = _pickStableProfileAvatarColor(widget.name?.trim().isNotEmpty == true ? widget.name!.trim() : widget.fileUuid);
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
    if (widget.statusColor == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 2,
          top: 2,
          child: Tooltip(
            message: _statusTooltipMessage(widget.statusColor!),
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
                color: widget.statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _statusTooltipMessage(Color c) {
    if (c.green >= c.red && c.green > 120) return 'Staff is signed in';
    if (c.red > 180 && c.green < 120) return 'Staff is absent';
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
