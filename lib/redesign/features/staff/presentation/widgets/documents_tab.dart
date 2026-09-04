import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/dashed_key.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6c's Documents tab: what is on file, what has run out, and one dashed key
/// to add another.
///
/// A row opens nothing. There is no read endpoint for a staff document, so
/// the row reports and does not pretend to be a link.
class DocumentsTab extends StatelessWidget {
  const DocumentsTab({required this.profile, this.onAdd, super.key});

  final StaffProfile profile;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.cardGap,
      children: <Widget>[
        for (final document in profile.documents)
          _DocumentRow(
            document: document,
            isExpired: profile.isExpired(document),
          ),
        if (onAdd != null)
          DashedKey(
            label: StaffStrings.addDocument,
            icon: AppIcons.plus,
            onTap: onAdd!,
          ),
        Text(
          StaffStrings.documentsFootnote,
          style: StaffTextStyles.footnote.copyWith(color: c.ink3),
        ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.isExpired});

  final StaffDocument document;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: StaffSizes.documentRowPad,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          Container(
            width: StaffSizes.documentTile,
            height: StaffSizes.documentTile,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.neutralBg,
              borderRadius: AppRadii.chipR,
            ),
            child: Text(
              document.kind == StaffDocumentKind.pdf
                  ? StaffStrings.kindPdf
                  : StaffStrings.kindImage,
              style: StaffTextStyles.documentKind.copyWith(color: c.ink2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  document.name,
                  style: StaffTextStyles.rowTitle.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _detail(),
                  style: StaffTextStyles.rowDetail.copyWith(color: c.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusPill(
            label: isExpired ? StaffStrings.expired : StaffStrings.onFile,
            tone: isExpired ? PillTone.danger : PillTone.success,
            small: true,
          ),
        ],
      ),
    );
  }

  String _detail() {
    final expires = document.expiresOn;
    if (expires != null) {
      return StaffStrings.documentExpires(
        document.type,
        StaffStrings.date(expires),
      );
    }
    final added = document.addedOn;
    return added == null
        ? document.type
        : StaffStrings.documentDetail(document.type, StaffStrings.date(added));
  }
}
