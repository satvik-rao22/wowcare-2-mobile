import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/show_full_screen_media.dart';

import '../../../../app/theme/media_res.dart';

class ActivityMediaPreview extends StatefulWidget {
  final ActivityItem activity;
  final Color activityColor;
  const ActivityMediaPreview({super.key, required this.activity, required this.activityColor});


  @override
  State<ActivityMediaPreview> createState() => _ActivityMediaPreviewState();
}

class _ActivityMediaPreviewState extends State<ActivityMediaPreview> {
  static final Map<String, dynamic> activityIcons = {
    'Nap': MediaRes.napActivityIcon,
    'Bathroom': MediaRes.bathroomActivityIcon,
    'Bottle': MediaRes.bottleActivityIcon,
    'Meal': MediaRes.mealActivityIcon,
    'Incident': MediaRes.incidentActivityIcon,
    'Photo': MediaRes.photoVideoActivityIcon,
    'Video': MediaRes.photoVideoActivityIcon,
    'Medication': MediaRes.medicationActivityIcon,
    'Notes': MediaRes.notesActivityIcon,
    'Outdoor': MediaRes.outdoorActivityIcon,
    'Learning': MediaRes.learningActivityIcon,
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isVideoRow(Map<String, dynamic> row) {
    final mt = (row['mediaType'] ?? '').toString().trim().toUpperCase();
    if (mt.contains('VIDEO')) return true;
    final delivery = (row['deliveryUrl'] ?? row['artifactUrl'] ?? row['originalDownloadUrl'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return delivery.endsWith('.mp4') ||
        delivery.endsWith('.mov') ||
        delivery.endsWith('.webm') ||
        delivery.endsWith('.m3u8');
  }

  String? _resolveVideoThumbnailUrl() {
    final rows = widget.activity.snapshotAttachments ?? const <Map<String, dynamic>>[];
    for (final r in rows) {
      if (!_isVideoRow(r)) continue;
      final thumb = (r['thumbnailUrl'] ?? '').toString().trim();
      if (thumb.isNotEmpty) return thumb;
      final delivery = (r['deliveryUrl'] ?? '').toString().trim();
      if (delivery.isNotEmpty) return delivery;
      final artifact = (r['artifactUrl'] ?? '').toString().trim();
      if (artifact.isNotEmpty) return artifact;
      final original = (r['originalDownloadUrl'] ?? '').toString().trim();
      if (original.isNotEmpty) return original;
    }
    return null;
  }

  bool _hasProcessingMedia() {
    final rows = widget.activity.snapshotAttachments ?? const <Map<String, dynamic>>[];
    for (final r in rows) {
      final status = (r['status'] ?? '').toString().trim().toUpperCase();
      final isProcessing =
          status == 'PROCESSING' || status == 'UPLOADED' || status == 'PENDING';
      if (!isProcessing) continue;
      // Treat as ready (not processing) once a servable URL exists — the
      // backend often keeps status == PROCESSING after the variants are live.
      if (!attachmentRowHasUsableMedia(r)) return true;
    }
    return false;
  }

  Widget _buildProcessingCard() {
    return Container(
      width: 122,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF4FF), Color(0xFFF5F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Processing...',
              style: TextStyle(
                color: Color(0xFF1F3B64),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconFallback() {
    final icon = activityIcons[widget.activity.name] ?? MediaRes.notesActivityIcon;
    return Container(
      width: 122,
      height: 76,
      color: widget.activityColor.withOpacity(0.25),
      child: Center(
        child: Image.asset(
          icon,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? videoUrl = widget.activity.videoUrl;
    final String? photoUrl = widget.activity.photoUrl;
    final bool hasVideo = videoUrl?.isNotEmpty == true;
    final bool hasPhoto = photoUrl?.isNotEmpty == true;
    final bool hasProcessingMedia = _hasProcessingMedia();
    final thumbUrl = hasVideo ? _resolveVideoThumbnailUrl() : null;
    return InkWell(
      onTap: () {
        if ( photoUrl?.isNotEmpty == true || videoUrl?.isNotEmpty == true) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShowFullScreenMedia(activity: widget.activity),
            ),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo)
            (thumbUrl != null && thumbUrl.trim().isNotEmpty)
                ? Image.network(
                    thumbUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, child, progress) =>
                        progress == null
                            ? child
                            : Container(color: widget.activityColor.withOpacity(0.3)),
                    errorBuilder: (c, e, s) => Container(
                      color: widget.activityColor.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.videocam_outlined,
                          color: Colors.white70,
                          size: 38,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: widget.activityColor.withOpacity(0.3),
                    child: const Center(
                      child: Icon(
                        Icons.videocam_outlined,
                        color: Colors.white70,
                        size: 38,
                      ),
                    ),
                  )
          else if (hasPhoto)
            Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, progress)=> progress == null ? child : Container(color: widget.activityColor.withOpacity(0.3)),
              errorBuilder: (c, e, s)=> _buildIconFallback(),

            )
          else if (hasProcessingMedia)
            _buildProcessingCard()
          else
            _buildIconFallback(),

          if (hasVideo)
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size : 50,
              ),
            ),
          if (hasProcessingMedia && !hasVideo)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PROCESSING',
                  style: TextStyle(
                    color: Color(0xFF1A56A5),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
