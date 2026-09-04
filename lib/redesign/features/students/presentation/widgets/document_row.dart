import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// One file on a student's record (5c Documents, 5f).
///
/// The square badge says what kind of file it is; square is a badge, round is
/// a person. The pill says whether it still counts, which is the only status
/// the backend keeps: there is no "missing", because nothing tells the app
/// what should have been there.
class DocumentRow extends StatelessWidget {
  const DocumentRow({required this.document, this.onTap, super.key});

  final StudentDocumentItem document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: onTap != null,
      label: document.name,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.keySecondary(c),
          padding: StudentsSizes.itemRowPad,
          child: Row(
            spacing: AppSizes.rowGap,
            children: <Widget>[
              SurfaceBox(
                surface: AppSurfaces.glyphTile(
                  c,
                  fill: c.altWell,
                  radius: AppRadii.chip,
                ),
                width: StudentsSizes.kindTile,
                height: StudentsSizes.kindTile,
                alignment: Alignment.center,
                child: Text(
                  document.kind == DocumentKind.image
                      ? StudentsStrings.kindImage
                      : StudentsStrings.kindPdf,
                  style: StudentsTextStyles.kindTile.copyWith(color: c.ink2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      document.name,
                      style: StudentsTextStyles.itemTitle.copyWith(
                        color: c.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      document.detail,
                      style: StudentsTextStyles.footnote.copyWith(
                        color: c.ink3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: document.isExpired
                    ? StudentsStrings.expired
                    : StudentsStrings.onFile,
                tone: document.isExpired ? PillTone.danger : PillTone.success,
                small: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
