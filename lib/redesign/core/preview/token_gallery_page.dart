import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_elevation.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Every token, on one screen, so the core layer can be checked against the
/// design frames on a real device.
///
/// This is scaffolding, not a screen in the app: it is what
/// `main_redesign.dart` boots into until the router lands in phase 2, and it
/// stays afterwards as the place to eyeball a token change.
class TokenGalleryPage extends StatelessWidget {
  const TokenGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenGutter,
            AppSizes.screenTopPad,
            AppSizes.screenGutter,
            AppSizes.screenBottomPad,
          ),
          children: <Widget>[
            _title(c),
            const SizedBox(height: AppSizes.space4),
            _surfacesSection(c),
            const SizedBox(height: AppSizes.space5),
            _keysSection(c),
            const SizedBox(height: AppSizes.space5),
            _statusSection(c),
            const SizedBox(height: AppSizes.space5),
            _typeSection(c),
          ],
        ),
      ),
    );
  }

  Widget _title(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Design components',
        style: AppTextStyles.moduleTitle.copyWith(color: c.ink),
      ),
      const SizedBox(height: AppSizes.space1),
      Text(
        'L4 warm tray, cool cards',
        style: AppTextStyles.subLine.copyWith(color: c.ink3),
      ),
    ],
  );

  Widget _eyebrow(Colourway c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.space2),
    child: Text(
      label.toUpperCase(),
      style: AppTextStyles.eyebrow.copyWith(color: c.pink),
    ),
  );

  Widget _surfacesSection(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _eyebrow(c, 'Surfaces'),
      SurfaceBox(
        surface: AppSurfaces.card(c),
        padding: AppSizes.rowPad,
        child: Text(
          'Raised card',
          style: AppTextStyles.cardTitle.copyWith(color: c.ink),
        ),
      ),
      const SizedBox(height: AppSizes.cardGap),
      SurfaceBox(
        surface: AppSurfaces.well(c),
        padding: AppSizes.fieldPad,
        child: Text(
          'Recessed well',
          style: AppTextStyles.fieldText.copyWith(color: c.ink3),
        ),
      ),
      const SizedBox(height: AppSizes.cardGap),
      SurfaceBox(
        surface: AppSurfaces.impact(c),
        padding: AppSizes.rowPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '18 of 22 signed in',
              style: AppTextStyles.cardTitle.copyWith(color: c.onImpact),
            ),
            Text(
              'Impact card',
              style: AppTextStyles.subLine.copyWith(color: c.onImpactSub),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _keysSection(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _eyebrow(c, 'Keys'),
      Pressable.key(
        onTap: () {},
        child: Container(
          padding: AppSizes.keyPrimaryPad,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.pink,
            borderRadius: AppRadii.innerR,
            boxShadow: AppElevation.keyPrimary(c),
          ),
          child: Text(
            'Sign In 6 students',
            style: AppTextStyles.keyLabel.copyWith(color: c.onPink),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.keyGap),
      Row(
        children: <Widget>[
          Expanded(
            child: Pressable.surface(
              onTap: () {},
              child: SurfaceBox(
                surface: AppSurfaces.card(c).copyWith(
                  decoration: BoxDecoration(
                    color: c.key,
                    borderRadius: AppRadii.innerR,
                    border: Border.all(color: c.keyBorder),
                    boxShadow: AppElevation.keySecondary(c),
                  ),
                ),
                padding: AppSizes.keySecondaryPad,
                alignment: Alignment.center,
                child: Text(
                  'More actions',
                  style: AppTextStyles.keyLabelSmall.copyWith(color: c.ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.keyGap),
          Expanded(
            child: Pressable.key(
              onTap: () {},
              child: Container(
                padding: AppSizes.keySecondaryPad,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.danger,
                  borderRadius: AppRadii.innerR,
                  boxShadow: AppElevation.keyDestructive(c),
                ),
                child: Text(
                  'Deactivate',
                  style: AppTextStyles.keyLabelSmall.copyWith(color: c.onPink),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSizes.keyGap),
      SurfaceBox(
        surface: AppSurfaces.well(c).copyWith(
          insets: AppElevation.keyDisabled(c),
        ),
        padding: AppSizes.keyPrimaryPad,
        alignment: Alignment.center,
        child: Text(
          'Pick students to act on',
          style: AppTextStyles.keyLabel.copyWith(color: c.ink3),
        ),
      ),
    ],
  );

  Widget _statusSection(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _eyebrow(c, 'Status'),
      Wrap(
        spacing: AppSizes.chipGap,
        runSpacing: AppSizes.chipGap,
        children: <Widget>[
          _pill(c, 'Signed In', c.successBg, c.successFg),
          _pill(c, 'Absent', c.dangerBg, c.dangerFg),
          _pill(c, 'Not Marked', c.neutralBg, c.neutralFg),
          _pill(c, 'Upcoming', c.staffBg, c.staffFg),
          _pill(c, 'Students', c.studentBg, c.student),
        ],
      ),
    ],
  );

  Widget _pill(Colourway c, String label, Color bg, Color fg) => Container(
    padding: AppSizes.pillPad,
    decoration: BoxDecoration(color: bg, borderRadius: AppRadii.pillR),
    child: Text(label, style: AppTextStyles.pillLabel.copyWith(color: fg)),
  );

  Widget _typeSection(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _eyebrow(c, 'Type'),
      Text('33.6', style: AppTextStyles.headlineCount.copyWith(color: c.dangerFg)),
      Text('Module title', style: AppTextStyles.moduleTitle.copyWith(color: c.ink)),
      Text('Detail title', style: AppTextStyles.detailTitle.copyWith(color: c.ink)),
      Text('Card title', style: AppTextStyles.cardTitle.copyWith(color: c.ink)),
      Text('Row name', style: AppTextStyles.rowName.copyWith(color: c.ink)),
      Text('Sub line', style: AppTextStyles.subLine.copyWith(color: c.ink3)),
      Text('Nav label', style: AppTextStyles.navLabel.copyWith(color: c.ink3)),
    ],
  );
}
