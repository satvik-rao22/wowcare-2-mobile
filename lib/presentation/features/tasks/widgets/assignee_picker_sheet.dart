import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

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
    super.key,
  });

  final List<({String code, String name})> options;
  final Map<String, String> initialSelection;
  final bool isLoading;

  /// Assignee codes that are already on the series and must stay selected —
  /// rendered checked and non-interactive.
  final Set<String> lockedCodes;

  @override
  State<AssigneePickerSheet> createState() => _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends State<AssigneePickerSheet> {
  late final Map<String, String> _selection = Map.of(widget.initialSelection);
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) =>
            _query.isEmpty ||
            o.name.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

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
                  color: Colors.grey[300],
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
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, size: 19),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: widget.isLoading && widget.options.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No active staff found',
                              style: TextStyle(color: Colors.grey[600]),
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
                                title: Text(
                                  staff.name.isNotEmpty
                                      ? staff.name
                                      : staff.code,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                                // Existing assignees can be added to but never
                                // removed here, so their tile is locked on.
                                subtitle: locked
                                    ? Text(
                                        'Already assigned',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
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
                    decoration: BoxDecoration(
                      gradient: AppColors.buildPrimaryGradient(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, _selection),
                      child: Text(
                        'Done (${_selection.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
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
