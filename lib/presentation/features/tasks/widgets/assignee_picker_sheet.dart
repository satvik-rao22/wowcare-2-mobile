import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_haptics.dart';

/// Searchable, multi-select assignee picker used by the task form. Add mode
/// creates one task per assignee (PRD FR-TK-03). Edit mode pre-checks the
/// existing series roster ([lockedCodes]) and leaves those tiles disabled so
/// they can't be removed, while still allowing new assignees to be added. Only
/// ACTIVE staff are passed in by the caller.
///
/// Pops with the resulting `code -> name` selection (always including the
/// locked entries) when "Done" is tapped, or `null` when dismissed.
class AssigneePickerSheet extends StatefulWidget {
  const AssigneePickerSheet({
    required this.options,
    required this.initialSelection,
    required this.isLoading,
    this.lockedCodes = const {},
    this.selfCodes = const {},
    super.key,
  });

  final List<({String code, String name})> options;
  final Map<String, String> initialSelection;
  final bool isLoading;

  /// Assignee codes that are already on the series and must stay selected —
  /// rendered checked and non-interactive.
  final Set<String> lockedCodes;

  /// The signed-in user's identity codes (`TasksState.identityCodes` — the
  /// module matches self on either the staff or the user code). Their row is
  /// pinned to the top, badged "Me", and also findable by typing "me". Empty
  /// while identity is unresolved, in which case no row is badged.
  final Set<String> selfCodes;

  @override
  State<AssigneePickerSheet> createState() => _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends State<AssigneePickerSheet> {
  late final Map<String, String> _selection = Map.of(widget.initialSelection);
  String _query = '';

  bool _isSelf(String code) => widget.selfCodes.contains(code);

  /// Matches on name, plus "me" for the signed-in user's own row so they can
  /// find themselves without recalling how the roster spells their name.
  bool _matchesQuery(({String code, String name}) option) {
    if (_query.isEmpty) return true;
    final query = _query.toLowerCase();
    if (option.name.toLowerCase().contains(query)) return true;
    return _isSelf(option.code) && 'me'.startsWith(query);
  }

  @override
  Widget build(BuildContext context) {
    // "Me" first, then alphabetical — the user's own row is the one most often
    // wanted, and pinning it keeps the badge visible without scrolling.
    final filtered = widget.options.where(_matchesQuery).toList()
      ..sort((a, b) {
        final selfA = _isSelf(a.code);
        if (selfA != _isSelf(b.code)) return selfA ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.sheetGrabber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select assignees',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search staff…',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppPalette.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 19),
                    isDense: true,
                    filled: true,
                    fillColor: AppSurfaces.fieldFill,
                    border: AppSurfaces.fieldBorder(radius: 10),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: widget.isLoading && widget.options.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No active staff found',
                              style: TextStyle(color: AppPalette.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final staff = filtered[index];
                              final checked =
                                  _selection.containsKey(staff.code);
                              final locked =
                                  widget.lockedCodes.contains(staff.code);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                activeColor: AppColors.themeColor,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        staff.name.isNotEmpty
                                            ? staff.name
                                            : staff.code,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13.5),
                                      ),
                                    ),
                                    // Badge rides on the row (not the index), so
                                    // it survives search filtering and sorting.
                                    if (_isSelf(staff.code)) ...[
                                      const SizedBox(width: 6),
                                      const _MeBadge(),
                                    ],
                                  ],
                                ),
                                // Existing assignees can be added to but never
                                // removed here, so their tile is locked on.
                                subtitle: locked
                                    ? const Text(
                                        'Already assigned',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppPalette.textSecondary,
                                        ),
                                      )
                                    : null,
                                onChanged: locked
                                    ? null
                                    : (_) {
                                        setState(() {
                                          if (checked) {
                                            _selection.remove(staff.code);
                                          } else {
                                            _selection[staff.code] = staff.name;
                                          }
                                        });
                                      },
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: DecoratedBox(
                    decoration: AppSurfaces.key(KeyVariant.primary, radius: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.tap();
                        Navigator.pop(context, _selection);
                      },
                      child: Text(
                        'Done (${_selection.length})',
                        style: TextStyle(
                          color: AppSurfaces.keyInk(KeyVariant.primary),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
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
}

/// Marks the signed-in user's row in the roster, so assigning a task to
/// yourself doesn't read like picking a stranger off a list.
class _MeBadge extends StatelessWidget {
  const _MeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.themeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 11, color: AppColors.themeColor),
          SizedBox(width: 3),
          Text(
            'Me',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.themeColor,
            ),
          ),
        ],
      ),
    );
  }
}
