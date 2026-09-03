import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// How loudly one card in the attention deck speaks.
///
/// Red is a thing already wrong, sun is a thing about to be, and navy is the
/// deck's one impact surface: the money card, which outranks the rest by
/// being the only one that changes colour entirely.
enum AttentionTone { danger, warn, impact }

/// The chrome every card in the attention deck shares: an eyebrow, a line, a
/// tinted glyph tile, and whatever the kind of card puts underneath.
class AttentionCard extends StatelessWidget {
  const AttentionCard({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.tone,
    required this.body,
    super.key,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final AttentionTone tone;

  /// The bottom half: a headline count, two wells, or a pair of lines.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isImpact = tone == AttentionTone.impact;

    return SurfaceBox(
      surface: isImpact
          ? AppSurfaces.impact(c)
          : AppSurfaces.card(c).copyWith(
              decoration: AppSurfaces.card(c).decoration.copyWith(
                border: Border.all(color: _line(c)),
              ),
            ),
      padding: AppSizes.cardPad,
      height: DashboardSizes.deckCardHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: DashboardSizes.attentionTitleGap,
                  children: <Widget>[
                    Text(
                      eyebrow.toUpperCase(),
                      style: DashboardTextStyles.attentionEyebrow.copyWith(
                        color: _ink(c),
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DashboardTextStyles.attentionTitle.copyWith(
                        color: isImpact ? c.onImpact : c.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.space2),
              _GlyphTile(icon: icon, tone: tone, colours: c),
            ],
          ),
          body,
        ],
      ),
    );
  }

  Color _line(Colourway c) => switch (tone) {
    AttentionTone.danger => c.dangerLine,
    AttentionTone.warn => c.staffLine,
    AttentionTone.impact => c.impact,
  };

  Color _ink(Colourway c) => switch (tone) {
    AttentionTone.danger => c.dangerFg,
    AttentionTone.warn => c.staffFg,
    AttentionTone.impact => c.staff,
  };
}

class _GlyphTile extends StatelessWidget {
  const _GlyphTile({
    required this.icon,
    required this.tone,
    required this.colours,
  });

  final IconData icon;
  final AttentionTone tone;
  final Colourway colours;

  /// How far the warm white is pulled back on the impact card's tile.
  static const double _onImpactAlpha = .12;

  @override
  Widget build(BuildContext context) {
    final fill = switch (tone) {
      AttentionTone.danger => colours.dangerBg,
      AttentionTone.warn => colours.staffBg,
      AttentionTone.impact => colours.onImpact.withValues(
        alpha: _onImpactAlpha,
      ),
    };
    final glyph = switch (tone) {
      AttentionTone.danger => colours.danger,
      AttentionTone.warn => colours.staffFg,
      AttentionTone.impact => colours.staff,
    };

    return Container(
      width: DashboardSizes.attentionIconTile,
      height: DashboardSizes.attentionIconTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, borderRadius: AppRadii.innerR),
      child: Icon(
        icon,
        size: DashboardSizes.attentionGlyph,
        color: glyph,
      ),
    );
  }
}
