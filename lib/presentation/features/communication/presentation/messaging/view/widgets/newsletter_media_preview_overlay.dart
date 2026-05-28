import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// Themed floating overlay for newsletter image preview (replaces full-screen black viewer).
Future<void> showNewsletterImagePreview(
  BuildContext context, {
  required String imageUrl,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close image preview',
    barrierColor: AppColors.primaryColor.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (BuildContext dialogContext, _, __) {
      return _NewsletterImagePreviewOverlay(imageUrl: imageUrl);
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _NewsletterImagePreviewOverlay extends StatelessWidget {
  const _NewsletterImagePreviewOverlay({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final double maxWidth = screen.width * 0.92;
    final double maxHeight = screen.height * 0.78;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: AppColors.fieldBackgroundColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 44, 12, 12),
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.85,
                            maxScale: 4,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.themeColor.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unable to load image',
                                    style: TextStyle(
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _ClosePreviewButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClosePreviewButton extends StatelessWidget {
  const _ClosePreviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.close_rounded,
            size: 22,
            color: AppColors.primaryColor.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
