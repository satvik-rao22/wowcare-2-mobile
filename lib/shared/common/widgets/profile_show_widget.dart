import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/color_utils.dart';
import 'package:wowcare/core/util/string_utils.dart';
import 'package:shimmer/shimmer.dart';
// Backend/bloc imports disabled for UI-only usage
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'dart:typed_data';
// import 'package:wowcare/core/util/typedefs.dart';
// import 'package:wowcare/src/documents/presentation/bloc/document_bloc.dart';

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
  }) : super(key: key);

  @override
  State<DocumentImageWidget> createState() => _DocumentImageWidgetState();
}

class _DocumentImageWidgetState extends State<DocumentImageWidget> {
  @override
  void initState() {
    super.initState();
    // Backend disabled: skip fetching, UI-only
    // if (widget.fileUuid.isNotEmpty) {
    //   _fetchDocument();
    // }
  }

  @override
  void didUpdateWidget(DocumentImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileUuid != oldWidget.fileUuid) {
      // Backend disabled: no fetch necessary in UI-only mode
    }
  }

  // Backend disabled: skip fetching, UI-only
  // void _fetchDocument() {
  //   DataMap parameters = {
  //     'fileUuid.equals': widget.fileUuid,
  //   };
  //   context.read<DocumentBloc>().add(DownloadDocument(parameters));
  // }

  @override
  Widget build(BuildContext context) {
    // UI-only: show initials if name is available; else placeholder image
    return GestureDetector(
      onTap: widget.onTap,
      child: (widget.name != null && widget.name!.isNotEmpty)
          ? _buildInitialsAvatar()
          : _buildPlaceholder(),
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

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      backgroundColor: ColorUtils.getColorFromName(
        widget.name!,
      ),
      radius: widget.size / 2,
      child: Text(
        StringUtils.getInitials(widget.name!),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: widget.fontSize,
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
        backgroundColor: ColorUtils.getColorFromName(
          widget.name!,
        ),
        radius: widget.size / 2,
        child: Text(
          StringUtils.getInitials(widget.name!),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: widget.fontSize,
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
