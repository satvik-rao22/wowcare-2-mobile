import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/attention_body.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/attention_card.dart';

/// 3A1's deck: whatever needs an Admin today, stacked, tapped through.
///
/// Nothing is dismissed. A card leaves the deck when the thing behind it is
/// dealt with, and never because it was swiped away, so the deck cannot be
/// emptied by ignoring it. Tapping cycles; the dots say where you are.
class AttentionDeck extends StatefulWidget {
  const AttentionDeck({required this.summary, required this.onOpen, super.key});

  final AttentionSummary summary;

  /// Where a card's own key goes: incidents to Activities, ratio to
  /// Classrooms, billing to Billing.
  final void Function(AttentionKind kind) onOpen;

  @override
  State<AttentionDeck> createState() => _AttentionDeckState();
}

class _AttentionDeckState extends State<AttentionDeck> {
  int _index = 0;

  void _next(int count) => setState(() => _index = (_index + 1) % count);

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final kinds = widget.summary.kinds;
    if (kinds.isEmpty) return const SizedBox.shrink();

    final index = _index % kinds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenGutter,
          ),
          child: SectionEyebrow(
            label: DashboardStrings.needsAttention,
            color: c.dangerFg,
            trailing: Text(
              DashboardStrings.deckCounter(index + 1, kinds.length),
              style: AppTextStyles.sectionLink.copyWith(color: c.ink3),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenGutter,
            DashboardSizes.deckTopGap,
            AppSizes.screenGutter,
            0,
          ),
          child: GestureDetector(
            onTap: () => _next(kinds.length),
            child: SizedBox(
              height: DashboardSizes.deckHeight,
              child: Stack(children: _stack(kinds, index)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: DashboardSizes.deckDotsTopGap),
          child: _Dots(count: kinds.length, index: index, colours: c),
        ),
      ],
    );
  }

  /// The cards behind the front one, drawn back to front so the top card wins
  /// hit testing and the two behind it peek out below it.
  List<Widget> _stack(List<AttentionKind> kinds, int index) {
    final visible = <Widget>[];

    for (var depth = DashboardSizes.deckVisibleBehind; depth >= 0; depth--) {
      if (depth >= kinds.length) continue;
      final kind = kinds[(index + depth) % kinds.length];
      visible.add(
        AnimatedPositioned(
          key: ValueKey<AttentionKind>(kind),
          duration: AppMotion.panel,
          curve: AppMotion.spring,
          left: 0,
          right: 0,
          top: _offset(depth),
          child: AnimatedScale(
            duration: AppMotion.panel,
            curve: AppMotion.spring,
            scale: _scale(depth),
            child: AttentionCard(
              eyebrow: kind.eyebrow,
              title: kind.titleFor(widget.summary),
              icon: kind.icon,
              tone: kind.tone,
              body: AttentionBody(
                kind: kind,
                summary: widget.summary,
                onOpen: () => widget.onOpen(kind),
              ),
            ),
          ),
        ),
      );
    }
    return visible;
  }

  static double _offset(int depth) => switch (depth) {
    0 => 0,
    1 => DashboardSizes.deckOffset1,
    _ => DashboardSizes.deckOffset2,
  };

  static double _scale(int depth) => switch (depth) {
    0 => 1,
    1 => DashboardSizes.deckScale1,
    _ => DashboardSizes.deckScale2,
  };
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.colours,
  });

  final int count;
  final int index;
  final Colourway colours;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: DashboardSizes.deckDotGap,
    children: <Widget>[
      for (int i = 0; i < count; i++)
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          width: i == index
              ? DashboardSizes.deckDotActiveWidth
              : DashboardSizes.deckDotWidth,
          height: DashboardSizes.deckDotHeight,
          decoration: BoxDecoration(
            color: i == index ? colours.pink : colours.deepWell,
            borderRadius: AppRadii.pillR,
          ),
        ),
    ],
  );
}

/// What each kind of card says and how loudly, kept beside the deck rather
/// than in the model: this is presentation, and the model is what the API
/// already returns.
extension on AttentionKind {
  String get eyebrow => switch (this) {
    AttentionKind.incidents => DashboardStrings.incidents,
    AttentionKind.ratio => DashboardStrings.ratio,
    AttentionKind.shifts => DashboardStrings.shifts,
    AttentionKind.movements => DashboardStrings.movements,
    AttentionKind.documents => DashboardStrings.documents,
    AttentionKind.checkups => DashboardStrings.documents,
    AttentionKind.billing => DashboardStrings.thisMonth,
  };

  IconData get icon => switch (this) {
    AttentionKind.incidents => AppIcons.fileText,
    AttentionKind.ratio => AppIcons.users,
    AttentionKind.shifts => AppIcons.clock,
    AttentionKind.movements => AppIcons.transfer,
    AttentionKind.documents => AppIcons.fileText,
    AttentionKind.checkups => AppIcons.checkCircle,
    AttentionKind.billing => AppIcons.billing,
  };

  AttentionTone get tone => switch (this) {
    AttentionKind.incidents => AttentionTone.danger,
    AttentionKind.ratio => AttentionTone.danger,
    AttentionKind.shifts => AttentionTone.warn,
    AttentionKind.movements => AttentionTone.warn,
    AttentionKind.documents => AttentionTone.warn,
    AttentionKind.checkups => AttentionTone.warn,
    AttentionKind.billing => AttentionTone.impact,
  };

  String titleFor(AttentionSummary s) => switch (this) {
    AttentionKind.incidents => DashboardStrings.incidentsTitle,
    AttentionKind.ratio => DashboardStrings.ratioTitle(s.ratioShortfalls.length),
    AttentionKind.shifts => DashboardStrings.shiftsTitle(
      s.openShift?.classroomName ?? '',
      s.openShift?.shortfall ?? 0,
    ),
    AttentionKind.movements => DashboardStrings.movementsTitle,
    AttentionKind.documents => DashboardStrings.documentsTitle,
    AttentionKind.checkups => DashboardStrings.documentsTitle,
    AttentionKind.billing => DashboardStrings.totalOutstanding,
  };
}
