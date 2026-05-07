import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/presentation/features/activities/widgets/checkbox_widget.dart';

class StaffPresentWidget extends StatefulWidget {
  const StaffPresentWidget({
    super.key,
    required this.staffName,
    this.isEditable = true,
    this.incidentActivity = false,
    this.onSigned,
    this.isAlreadySigned = false,
    this.clickToSignEditable,
    this.fieldLabel = 'Staff Present',
    this.showSignCheckbox = true,
    this.signActionLabel = 'Click to sign',
    this.prefillWithStaffName = false,
    this.showStaffDropdown = true,
    this.signatureEncodedValue,
    this.onStaffChanged,
    this.matchStaffDirectoryForDisplay = true,
  });
  final String staffName;
  final bool isEditable;
  final bool incidentActivity;
  final ValueChanged<bool>? onSigned;
  final bool isAlreadySigned;
  final bool? clickToSignEditable;
  final String fieldLabel;
  final bool showSignCheckbox;
  final String signActionLabel;
  final bool prefillWithStaffName;
  final bool showStaffDropdown;
  final String? signatureEncodedValue;
  final void Function(String? selectedName, String? selectedCode)? onStaffChanged;

  /// When false, [staffName] is shown as-is (e.g. guardian name from profile API).
  /// When true, names may match the staff directory case-insensitive (can distort casing).
  final bool matchStaffDirectoryForDisplay;

  @override
  State<StaffPresentWidget> createState() => _StaffPresentWidgetState();
}

class _StaffPresentWidgetState extends State<StaffPresentWidget> {
 List<String> staffList = const <String>[];
 String? selectedStaff;
 bool clickToSign = false;
 final List<String> _fetchedStaffNames = [];
final Map<String, String> _staffCodeByNameLower = <String, String>{};
final Map<String, String> _staffNameByCodeLower = <String, String>{};
 bool _loadingStaffs = false;
  @override
  void initState(){
    super.initState();
    _rebuildStaffSelection();
    clickToSign = widget.isAlreadySigned;
    _loadStaffNames();
  }

  @override
  void didUpdateWidget(StaffPresentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staffName.trim() != widget.staffName.trim() ||
        oldWidget.matchStaffDirectoryForDisplay !=
            widget.matchStaffDirectoryForDisplay) {
      setState(_rebuildStaffSelection);
    }
    if (oldWidget.isAlreadySigned != widget.isAlreadySigned) {
      setState(() {
        clickToSign = widget.isAlreadySigned;
      });
    }
  }

  void _rebuildStaffSelection() {
    final incomingName = _resolveDisplayName(widget.staffName.trim());
    final currentName = _resolveDisplayName((selectedStaff ?? '').trim());
    final seedName = incomingName.isNotEmpty ? incomingName : currentName;
    final unique = <String>{};
    final ordered = <String>[];
    void addName(String value) {
      final v = value.trim();
      if (v.isEmpty) return;
      if (unique.add(v.toLowerCase())) ordered.add(v);
    }
    addName(seedName);
    if (widget.isEditable) {
      for (final n in _fetchedStaffNames) {
        addName(n);
      }
    }
    staffList = [
      ...ordered,
    ];
    if (seedName.isNotEmpty) {
      selectedStaff = staffList.firstWhere(
        (s) => s.toLowerCase() == seedName.toLowerCase(),
        orElse: () => seedName,
      );
      if (!staffList.any((s) => s.toLowerCase() == selectedStaff!.toLowerCase())) {
        staffList = [selectedStaff!, ...staffList];
      }
      _emitStaffChanged();
      return;
    }
    final current = (selectedStaff ?? '').trim();
    if (current.isNotEmpty &&
        staffList.any((s) => s.toLowerCase() == current.toLowerCase())) {
      selectedStaff = staffList.firstWhere(
        (s) => s.toLowerCase() == current.toLowerCase(),
      );
      _emitStaffChanged();
      return;
    }
    selectedStaff = staffList.isNotEmpty
        ? staffList.first
        : (currentName.isNotEmpty ? currentName : null);
    _emitStaffChanged();
  }

  String _resolveDisplayName(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (!widget.matchStaffDirectoryForDisplay) return t;
    for (final n in _fetchedStaffNames) {
      if (n.toLowerCase() == t.toLowerCase()) return n;
    }
    final fromCode = _staffNameByCodeLower[t.toLowerCase()];
    if ((fromCode ?? '').trim().isNotEmpty) return fromCode!.trim();
    return t;
  }

  void _emitStaffChanged() {
    final selected = (selectedStaff ?? '').trim();
    final code =
        selected.isEmpty ? null : _staffCodeByNameLower[selected.toLowerCase()];
    widget.onStaffChanged?.call(selectedStaff, code);
  }

  void _applyStaffMemberItems(List<StaffMember> items) {
    _fetchedStaffNames
      ..clear()
      ..addAll(
        items
            .map((e) => e.name.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
      );
    _staffCodeByNameLower.clear();
    _staffNameByCodeLower.clear();
    for (final staff in items) {
      final name = staff.name.trim();
      final code = staff.code.trim();
      if (name.isEmpty || code.isEmpty) continue;
      _staffCodeByNameLower[name.toLowerCase()] = code;
      _staffNameByCodeLower[code.toLowerCase()] = name;
    }
  }

  Future<void> _loadStaffNames() async {
    if (_loadingStaffs) return;
    _loadingStaffs = true;
    try {
      final storage = serviceLocator<StorageService>();
      final org =
          (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty) return;

      final repo = serviceLocator<StaffRepository>();
      if (repo is StaffRepositoryWithCache) {
        try {
          final cached = await (repo as StaffRepositoryWithCache)
              .loadCachedStaffPage(school, status: 'ACTIVE');
          if (cached != null && cached.items.isNotEmpty) {
            _applyStaffMemberItems(cached.items);
            if (mounted) setState(_rebuildStaffSelection);
            return;
          }
        } catch (_) {}
      }

      final useCase = serviceLocator<GetStaffPageUseCase>();
      final page = await useCase(
        organizationCode: org,
        schoolCode: school,
        page: 0,
        size: 300,
        status: 'ACTIVE',
      );
      _applyStaffMemberItems(page.items);
      if (!mounted) return;
      setState(_rebuildStaffSelection);
    } catch (_) {
      // Silent fallback to logged-in staff only.
    } finally {
      _loadingStaffs = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final signEditable = widget.clickToSignEditable ?? widget.isEditable;
    // While the user can toggle "Click to sign", do not reveal the scripted
    // signature band from a pre-filled fingerprint until checked.
    final gateSignatureRevealOnIncidentCheckbox =
        widget.incidentActivity && widget.showSignCheckbox && signEditable;
    final showIncidentSignatureBand = widget.incidentActivity &&
        (gateSignatureRevealOnIncidentCheckbox
            ? clickToSign
            : (clickToSign ||
                (widget.signatureEncodedValue ?? '').trim().isNotEmpty));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize:  13,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Manrope',
                ),
                children: [
                  TextSpan(text: widget.fieldLabel),
                  const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            if (widget.incidentActivity)
              widget.showSignCheckbox
                  ? CheckboxWidget(
                      label: widget.signActionLabel,
                      isEditable: signEditable,
                      isChecked: clickToSign,
                      onChecked: signEditable
                          ? (newValue) {
                              setState(() {
                                clickToSign = newValue;
                              });
                              widget.onSigned?.call(newValue);
                            }
                          : null,
                    )
                  : const SizedBox.shrink(),
          ],
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0 ),
        if (widget.showStaffDropdown)
          InkWell(
            onTap: null,
            child: Opacity(
              opacity: widget.isEditable ? 1.0 : 0.4,
              child: CustomDropdown(
                hintText: 'Select present staff',
                items: staffList,
                selectedItem: selectedStaff,
                isEnabled: widget.isEditable,
                onSelect: widget.isEditable?
                (String? value) {
                  setState(() {
                    selectedStaff = value;
                  });
                  _emitStaffChanged();
                }: null,
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x1AB1AFE9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66573353)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              selectedStaff ?? widget.staffName,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff573353),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        SizedBox(height: responsive.verticalSpacing,),
        if (showIncidentSignatureBand)
          Container(
            constraints: const BoxConstraints(minHeight: 60),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFB1AFE9).withOpacity(0.102),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                    selectedStaff ?? widget.staffName,
                    style: const TextStyle(
                      fontFamily: 'MervaleScript',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff573353),
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    ),
                  ),
                  if ((widget.signatureEncodedValue ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SelectableText(
                      'Signature-ID - ${widget.signatureEncodedValue!.trim()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0x80573353),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
      ],
    );
  }
  // Widget _buildCustomDropdown(
  //     String hintText,
  //     List<String> items,
  //     String? selectedItem,
  //     ValueChanged<String?> onSelect, {
  //       bool isRequired = false,
  //       double? height = null
  //     }) {
  //   final responsive = ResponsiveHelper(context);
  //   return CustomDropdown(
  //     label: null,
  //     hintText: hintText,
  //     items: items,
  //     height: height,
  //     selectedItem: selectedItem,
  //     onSelect: onSelect,
  //     showAsterisk: isRequired,
  //     labelStyle: TextStyle(
  //       fontSize: responsive.labelFontSize,
  //       fontFamily: "Manrope",
  //       fontWeight: FontWeight.w400,
  //       color: const Color(0xff573353),
  //     ),
  //     labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
  //     fieldHeight: responsive.isTablet ? 64.0 : 56.0,
  //     selectedTextStyle: TextStyle(
  //       fontFamily: 'Manrope',
  //       fontSize: responsive.inputFontSize,
  //       fontWeight: FontWeight.w600,
  //       color: const Color(0xff573353),
  //       height: 19 / 14,
  //     ),
  //     popupItemTextStyle: TextStyle(
  //       fontFamily: 'Manrope',
  //       fontSize: responsive.inputFontSize,
  //       fontWeight: FontWeight.w400,
  //       color: const Color(0xff573353),
  //     ),
  //     contentPadding: EdgeInsets.symmetric(
  //       horizontal: responsive.isTablet ? 16.0 : 12.0,
  //       vertical: responsive.isTablet ? 16.0 : 12.0,
  //     ),
  //   );
  // }
}
