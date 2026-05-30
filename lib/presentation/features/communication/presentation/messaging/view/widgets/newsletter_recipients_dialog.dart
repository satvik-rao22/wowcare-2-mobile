import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_recipient.dart';
import 'package:wowcare/domain/features/newsletter/repositories/newsletter_repository.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/newsletter_recipient_name_resolver.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

Future<void> showNewsletterRecipientsDialog({
  required BuildContext context,
  required String newsletterCode,
  List<NewsletterRecipient> recipients = const <NewsletterRecipient>[],
  Newsletter? cachedNewsletter,
}) async {
  final String code = newsletterCode.trim();
  if (code.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _NewsletterRecipientsSheet(
          newsletterCode: code,
          initialRecipients: recipients,
          cachedNewsletter: cachedNewsletter,
        ),
      );
    },
  );
}

class _NewsletterRecipientsSheet extends StatefulWidget {
  const _NewsletterRecipientsSheet({
    required this.newsletterCode,
    required this.initialRecipients,
    this.cachedNewsletter,
  });

  final String newsletterCode;
  final List<NewsletterRecipient> initialRecipients;
  final Newsletter? cachedNewsletter;

  @override
  State<_NewsletterRecipientsSheet> createState() =>
      _NewsletterRecipientsSheetState();
}

class _NewsletterRecipientsSheetState extends State<_NewsletterRecipientsSheet> {
  List<NewsletterRecipient> _recipients = const <NewsletterRecipient>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    List<NewsletterRecipient> resolved = widget.initialRecipients;
    if (resolved.isEmpty && widget.cachedNewsletter != null) {
      resolved = widget.cachedNewsletter!.recipients;
    }

    try {
      if (resolved.isEmpty) {
        final Newsletter newsletter =
            await serviceLocator<NewsletterRepository>()
                .getNewsletterByCode(widget.newsletterCode);
        resolved = newsletter.recipients;
      }

      resolved = await enrichNewsletterRecipientNames(resolved);

      if (!mounted) return;
      setState(() {
        _recipients = resolved;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load newsletter recipients.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final horizontalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
    final buttonHeight = isLargeTablet ? 56.0 : (isTablet ? 48.0 : 40.0);
    final buttonFontSize = isLargeTablet ? 18.0 : (isTablet ? 16.0 : 14.0);
    final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

    final String title = _isLoading
        ? 'Recipients'
        : 'Recipients (${_recipients.length})';

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargeTablet ? 1200.0 : double.infinity,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: verticalPadding,
            bottom: verticalPadding + bottomSafe,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: verticalPadding / 2),
              Center(
                child: Container(
                  width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  decoration: BoxDecoration(
                    gradient: AppColors.buildPrimaryGradient(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    color: Colors.white,
                    size: isLargeTablet ? 40 : 36,
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff573353),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!_isLoading && _errorMessage == null && _recipients.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Students this newsletter was sent to',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: verticalPadding * 0.75),
              _buildContent(
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                borderRadius: borderRadius,
              ),
              SizedBox(height: verticalPadding * 1.5),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius / 2),
                    gradient: AppColors.buildPrimaryGradient(),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius / 2),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required bool isTablet,
    required bool isLargeTablet,
    required double horizontalPadding,
    required double verticalPadding,
    required double borderRadius,
  }) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding / 2,
          vertical: verticalPadding / 2,
        ),
        child: Text(
          _errorMessage!,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor.withValues(alpha: 0.75),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_recipients.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding / 2,
          vertical: verticalPadding / 2,
        ),
        child: Text(
          'No student recipients found for this newsletter.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor.withValues(alpha: 0.75),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final double avatarSize = isLargeTablet ? 48 : (isTablet ? 44 : 40);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _recipients.length,
        separatorBuilder: (_, __) => SizedBox(height: verticalPadding / 3),
        itemBuilder: (BuildContext context, int index) {
          final NewsletterRecipient recipient = _recipients[index];
          final String studentCode = recipient.studentCode.trim();
          final String name = recipient.displayName;

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding / 2,
              vertical: isTablet ? 12 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius / 2),
              border: Border.all(color: AppColors.cardBorderColor),
            ),
            child: Row(
              children: [
                DocumentImageWidget(
                  fileUuid: studentCode,
                  studentCode: studentCode.isNotEmpty ? studentCode : null,
                  name: name,
                  size: avatarSize,
                  fontSize: isTablet ? 15 : 14,
                  disableAttendanceStatusLookup: true,
                ),
                SizedBox(width: horizontalPadding / 3),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff573353),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
