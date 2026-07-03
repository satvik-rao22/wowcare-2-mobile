import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';

/// PRD 2.3 — Info / Status popup.
///
/// Shows the original message content, a "Delivered To" list, and a
/// "Read By" list derived from [MessageEntity.readReceipts].
///
/// Optionally accepts [onFetchReceipts] — when provided the dialog fires it
/// on open to load display names from REST (Firestore maps carry only
/// timestamps, never names).
///
/// Usage:
/// ```dart
/// MessageStatusDialog.show(context, message: msg, onFetchReceipts: cb);
/// ```
class MessageStatusDialog extends StatefulWidget {
  const MessageStatusDialog({
    super.key,
    required this.message,
    this.onFetchReceipts,
  });

  final MessageEntity message;

  /// Optional async callback that returns an enriched receipt list with
  /// display names. When null the dialog falls back to showing [userCode].
  final Future<List<ReadReceiptEntity>> Function(String messageCode)?
      onFetchReceipts;

  static Future<void> show(
    BuildContext context, {
    required MessageEntity message,
    Future<List<ReadReceiptEntity>> Function(String messageCode)?
        onFetchReceipts,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => MessageStatusDialog(
        message: message,
        onFetchReceipts: onFetchReceipts,
      ),
    );
  }

  @override
  State<MessageStatusDialog> createState() => _MessageStatusDialogState();
}

class _MessageStatusDialogState extends State<MessageStatusDialog> {
  late List<ReadReceiptEntity> _receipts;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _receipts = widget.message.readReceipts;
    if (widget.onFetchReceipts != null) {
      _loadReceipts();
    }
  }

  Future<void> _loadReceipts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final fetched =
          await widget.onFetchReceipts!(widget.message.code);
      if (mounted) {
        setState(() {
          _receipts = fetched;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readBy = _receipts.where((r) => r.isRead).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Message Status',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.primaryColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original message preview
                  _SectionLabel(label: 'Message'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      widget.message.text.isEmpty
                          ? '(attachment)'
                          : _plainText(widget.message.text),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3436),
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delivered To
                  _SectionLabel(label: 'Delivered To (${_receipts.length})'),
                  const SizedBox(height: 8),
                  if (_receipts.isEmpty)
                    const _EmptyNote(text: 'No delivery receipts yet.')
                  else
                    ..._receipts.map(
                      (r) => _ReceiptTile(
                        name: r.userName.isNotEmpty ? r.userName : r.userCode,
                        timestamp: r.deliveredAt,
                        icon: Icons.done_all_rounded,
                        iconColor: const Color(0xFF636E72),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Read By
                  _SectionLabel(label: 'Read By (${readBy.length})'),
                  const SizedBox(height: 8),
                  if (readBy.isEmpty)
                    const _EmptyNote(text: 'No read receipts yet.')
                  else
                    ...readBy.map(
                      (r) => _ReceiptTile(
                        name: r.userName.isNotEmpty ? r.userName : r.userCode,
                        timestamp: r.readAt,
                        icon: Icons.done_all_rounded,
                        iconColor: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Strips HTML tags for plain-text preview.
  static String _plainText(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor.withValues(alpha: 0.6),
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Receipt tile ──────────────────────────────────────────────────────────────

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({
    required this.name,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
  });

  final String name;
  final DateTime? timestamp;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
          if (timestamp != null)
            Text(
              _formatTimestamp(timestamp!),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF636E72),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final local = SchoolZoneDateTime.dateTimeFromInstantInSchool(dt, tz);
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return MessageContentProcessor.smartBubbleTime(dt, '$hh:$mm');
  }
}

// ── Empty note ────────────────────────────────────────────────────────────────

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFFB2BEC3),
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
