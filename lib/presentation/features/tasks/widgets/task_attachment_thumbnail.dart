// SUPERSEDED — replaced by the shared attachment view layer:
//   lib/shared/services/attachment_view/attachment_asset_service.dart (resolve + cache)
//   lib/shared/common/widgets/attachment_view/ (thumbnail, section, viewer)
//
// This resolved URLs through AssetService, whose cache had no TTL — an
// expired presigned link stayed cached and rendered as a broken image — and it
// could not tell "failed" from "still loading", so a failed fetch showed an
// indefinite spinner. The shared service returns failure as a value and the
// shared widgets show it with a Retry.
//
// Full source in git history.
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
// import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
// import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';
// import 'package:wowcare/shared/services/asset/asset_service.dart';
//
// /// Square preview for one attachment: the image itself for pictures, a play
// /// badge over the poster for video, and a tinted doctype glyph for everything
// /// else.
// ///
// /// Image URLs are resolved lazily by asset code. The resolution is seeded from
// /// [AssetService]'s synchronous cache so an already-known asset paints on
// /// the first frame — important on a scrolling list, where a loading flicker per
// /// recycled card would be very visible.
// ///
// /// **Never guess a type from the URL to decide whether to paint.** An attachment
// /// known only by its asset code (from a task's `assetCodes`) has no type, and the
// /// delivery URL is a pre-signed link that usually carries no file extension — so
// /// anything gated on "is this an image?" silently shows nothing for exactly those
// /// attachments. Instead, whenever the attachment is not *known* to be a
// /// non-image, the resolved URL is simply painted, and failing to decode it falls
// /// back to the doctype glyph. That path needs no type information at all.
// ///
// /// Bytes are cached on disk by [CachedNetworkImage] under the **asset code**, not
// /// the URL: delivery URLs are short-lived and change per resolution, so a
// /// URL-keyed cache would miss every time. The asset code is globally unique per
// /// file, so two tasks can never collide on it — and two tasks that genuinely
// /// share one asset correctly share one cache entry.
// class TaskAttachmentThumbnail extends StatefulWidget {
//   const TaskAttachmentThumbnail({
//     required this.attachment,
//     required this.uploadService,
//     this.size = 56,
//     this.borderRadius = 10,
//     super.key,
//   });
//
//   final TaskAttachment attachment;
//   final AssetService uploadService;
//   final double size;
//   final double borderRadius;
//
//   @override
//   State<TaskAttachmentThumbnail> createState() =>
//       _TaskAttachmentThumbnailState();
// }
//
// class _TaskAttachmentThumbnailState extends State<TaskAttachmentThumbnail> {
//   String? _url;
//
//   /// True only while a resolution is actually in flight. Tracked explicitly
//   /// because "resolving" and "resolved to nothing" must look different: a
//   /// spinner that is never turned off is indistinguishable from a hung load.
//   bool _resolving = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _resolve();
//   }
//
//   @override
//   void didUpdateWidget(covariant TaskAttachmentThumbnail oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Recycled onto a different attachment: drop the previous URL before
//     // resolving, or this tile would keep painting the old file's image.
//     if (oldWidget.attachment.assetCode != widget.attachment.assetCode ||
//         oldWidget.attachment.url != widget.attachment.url) {
//       _url = null;
//       _resolving = false;
//       _resolve();
//     }
//   }
//
//   /// Whether this attachment could be paintable as an image. True when the
//   /// payload says it is one, and also when the payload says nothing at all —
//   /// unknown means "try it", not "give up".
//   bool get _mayBeImage {
//     final attachment = widget.attachment;
//     return attachment.isImage || !attachment.hasKnownType;
//   }
//
//   void _resolve() {
//     final attachment = widget.attachment;
//     // Known video/documents render from their own glyph and resolve on tap; a
//     // video still resolves if the payload gave it a poster to show.
//     final wantsUrl = _mayBeImage || attachment.thumbnailUrl.trim().isNotEmpty;
//     if (!wantsUrl || !attachment.isReady) return;
//
//     final direct = attachment.thumbnailUrl.trim().isNotEmpty
//         ? attachment.thumbnailUrl.trim()
//         : attachment.url.trim();
//     if (direct.isNotEmpty) {
//       _url = direct;
//       return;
//     }
//
//     if (attachment.assetCode.trim().isEmpty) return;
//
//     final cached =
//         widget.uploadService.cachedMediaAssetUrl(attachment.assetCode);
//     if (cached != null && cached.isNotEmpty) {
//       _url = cached;
//       return;
//     }
//
//     _resolving = true;
//     TaskAttachmentUtils.resolveUrl(attachment, widget.uploadService)
//         .then((value) {
//       if (!mounted) return;
//       setState(() {
//         _resolving = false;
//         if (value.isNotEmpty) _url = value;
//       });
//     }).catchError((_) {
//       if (!mounted) return;
//       setState(() => _resolving = false);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final radius = BorderRadius.circular(widget.borderRadius);
//     return ClipRRect(
//       borderRadius: radius,
//       child: SizedBox(
//         width: widget.size,
//         height: widget.size,
//         child: _content(),
//       ),
//     );
//   }
//
//   Widget _content() {
//     final attachment = widget.attachment;
//     final url = _url;
//
//     // A poster for a known video paints the frame with a play badge over it.
//     if (attachment.isVideo) {
//       return url == null ? _videoGlyph() : _videoPoster(url);
//     }
//
//     if (!_mayBeImage) return _docGlyph();
//
//     if (url == null) {
//       // No URL yet: spin only while a resolution is genuinely running, and show
//       // the neutral image placeholder once it has finished with nothing. A
//       // permanent spinner is what made these tiles look broken.
//       return _placeholder(showSpinner: _resolving);
//     }
//
//     // Paint it without knowing the type. If the bytes turn out not to be an
//     // image, [errorBuilder] falls back to the doctype glyph — which is also the
//     // right answer for a PDF that arrived with no metadata.
//     return _image(url);
//   }
//
//   Widget _image(String url) {
//     return CachedNetworkImage(
//       imageUrl: url,
//       // Keyed by asset code, never by URL — see the class doc. Falls back to the
//       // URL for a payload-supplied link that has no asset code behind it.
//       cacheKey: widget.attachment.assetCode.trim().isEmpty
//           ? null
//           : widget.attachment.assetCode.trim(),
//       width: widget.size,
//       height: widget.size,
//       fit: BoxFit.cover,
//       // Decode at the size actually drawn: a 4 MB photo in a 44 px tile is a
//       // needless decode into memory on every card in the list.
//       memCacheWidth: (widget.size * 3).round(),
//       placeholder: (_, __) => _placeholder(showSpinner: true),
//       errorWidget: (_, __, ___) => _docGlyph(),
//     );
//   }
//
//   /// The video's poster frame with a play badge over it.
//   Widget _videoPoster(String url) {
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         _image(url),
//         DecoratedBox(
//           decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25)),
//           child: Center(
//             child: Icon(
//               Icons.play_circle_fill_rounded,
//               size: widget.size * 0.48,
//               color: Colors.white.withValues(alpha: 0.92),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _placeholder({required bool showSpinner}) {
//     return Container(
//       color: const Color(0xFFF1F2F6),
//       alignment: Alignment.center,
//       child: showSpinner
//           ? SizedBox(
//               width: widget.size * 0.3,
//               height: widget.size * 0.3,
//               child: const CircularProgressIndicator(strokeWidth: 2),
//             )
//           : Icon(
//               Icons.image_outlined,
//               size: widget.size * 0.42,
//               color: const Color(0xFF9AA1AE),
//             ),
//     );
//   }
//
//   Widget _videoGlyph() {
//     return Container(
//       color: const Color(0xFF1F2430),
//       alignment: Alignment.center,
//       child: Icon(
//         Icons.play_circle_fill_rounded,
//         size: widget.size * 0.48,
//         color: Colors.white.withValues(alpha: 0.92),
//       ),
//     );
//   }
//
//   Widget _docGlyph() {
//     final attachment = widget.attachment;
//     final style = TaskAttachmentUtils.docTypeStyle(
//       attachment.fileName,
//       attachment.contentType,
//     );
//     return _DocTypeTile(
//       icon: style.icon,
//       color: style.color,
//       label: TaskAttachmentUtils.extensionLabel(attachment.fileName),
//       size: widget.size,
//     );
//   }
// }
//
// /// The same square preview for a locally picked file that hasn't been uploaded
// /// yet — reads straight off disk, so there is nothing to resolve.
// class PendingAttachmentThumbnail extends StatelessWidget {
//   const PendingAttachmentThumbnail({
//     required this.attachment,
//     this.size = 56,
//     this.borderRadius = 10,
//     super.key,
//   });
//
//   final PickedFile attachment;
//   final double size;
//   final double borderRadius;
//
//   @override
//   Widget build(BuildContext context) {
//     final radius = BorderRadius.circular(borderRadius);
//     final style = TaskAttachmentUtils.docTypeStyle(
//       attachment.name,
//       attachment.mimeType,
//     );
//     return ClipRRect(
//       borderRadius: radius,
//       child: SizedBox(
//         width: size,
//         height: size,
//         child: attachment.isImage
//             ? Image.file(
//                 attachment.file,
//                 width: size,
//                 height: size,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => _DocTypeTile(
//                   icon: style.icon,
//                   color: style.color,
//                   label: TaskAttachmentUtils.extensionLabel(
//                     attachment.name,
//                   ),
//                   size: size,
//                 ),
//               )
//             : _DocTypeTile(
//                 icon: style.icon,
//                 color: style.color,
//                 label: TaskAttachmentUtils.extensionLabel(attachment.name),
//                 size: size,
//               ),
//       ),
//     );
//   }
// }
//
// /// Tinted glyph + extension caption used wherever a file has no visual preview.
// class _DocTypeTile extends StatelessWidget {
//   const _DocTypeTile({
//     required this.icon,
//     required this.color,
//     required this.label,
//     required this.size,
//   });
//
//   final IconData icon;
//   final Color color;
//   final String label;
//   final double size;
//
//   @override
//   Widget build(BuildContext context) {
//     // Below this there is no room for both a glyph and a caption, so the
//     // glyph alone carries the meaning.
//     final showLabel = size >= 40;
//     // Floored so the caption stays legible on the small card-strip tiles
//     // rather than shrinking with the box.
//     final labelSize = (size * 0.16).clamp(9.0, 13.0);
//     return Container(
//       color: color.withValues(alpha: 0.10),
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: size * (showLabel ? 0.38 : 0.5), color: color),
//           if (showLabel) ...[
//             SizedBox(height: size * 0.04),
//             Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.clip,
//               style: TextStyle(
//                 fontSize: labelSize,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.3,
//                 color: color,
//                 height: 1,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
