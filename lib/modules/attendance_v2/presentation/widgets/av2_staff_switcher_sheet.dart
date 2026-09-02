import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../domain/entities/av2_staff_summary.dart';

/// Admin "switch staff" picker — searchable list of staff with avatars; the
/// current staff is highlighted. Returns the selected member.
Future<Av2StaffSummary?> showAv2StaffSwitcherSheet(
  BuildContext context, {
  required List<Av2StaffSummary> staff,
  required String currentCode,
}) {
  return showModalBottomSheet<Av2StaffSummary>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (context) => _StaffSwitcherSheet(staff: staff, currentCode: currentCode),
  );
}

class _StaffSwitcherSheet extends StatefulWidget {
  const _StaffSwitcherSheet({required this.staff, required this.currentCode});
  final List<Av2StaffSummary> staff;
  final String currentCode;

  @override
  State<_StaffSwitcherSheet> createState() => _StaffSwitcherSheetState();
}

class _StaffSwitcherSheetState extends State<_StaffSwitcherSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Av2StaffSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.staff
        : widget.staff
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                s.subtitle.toLowerCase().contains(q))
            .toList();
    // Keep the current staff pinned to the top.
    final sorted = [...list]..sort((a, b) {
        if (a.code == widget.currentCode) return -1;
        if (b.code == widget.currentCode) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.7;
    final list = _filtered;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Av2Spacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Av2Colors.border,
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Av2Spacing.md, Av2Spacing.md, Av2Spacing.md, Av2Spacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text('Switch staff', style: Av2Text.title)),
                    Text('${widget.staff.length}',
                        style: Av2Text.caption.copyWith(
                            color: Av2Colors.textSecondary)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Av2Spacing.md),
                child: _searchField(),
              ),
              const SizedBox(height: Av2Spacing.xs),
              Flexible(
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(Av2Spacing.lg),
                        child: Text('No staff found',
                            style: Av2Text.body
                                .copyWith(color: Av2Colors.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            Av2Spacing.sm, 0, Av2Spacing.sm, Av2Spacing.sm),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _tile(list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: (v) => setState(() => _query = v),
      style: Av2Text.body,
      decoration: InputDecoration(
        hintText: 'Search staff',
        hintStyle: Av2Text.body.copyWith(color: Av2Colors.textTertiary),
        prefixIcon:
            const Icon(Icons.search, size: 20, color: Av2Colors.textSecondary),
        filled: true,
        fillColor: Av2Colors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          borderSide: const BorderSide(color: Av2Colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          borderSide: const BorderSide(color: Av2Colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          borderSide: const BorderSide(color: Av2Colors.theme),
        ),
      ),
    );
  }

  Widget _tile(Av2StaffSummary s) {
    final selected = s.code == widget.currentCode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, s),
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Av2Colors.surfaceMuted : Colors.transparent,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            border: Border.all(
              color: selected ? Av2Colors.theme : Av2Colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Av2Colors.avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Text(s.initials,
                    style: Av2Text.bodyMedium.copyWith(
                        color: Av2Colors.avatarText, fontSize: 14)),
              ),
              const SizedBox(width: Av2Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.name,
                        style: Av2Text.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (s.subtitle.isNotEmpty)
                      Text(s.subtitle,
                          style: Av2Text.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, size: 20, color: Av2Colors.theme),
            ],
          ),
        ),
      ),
    );
  }
}
