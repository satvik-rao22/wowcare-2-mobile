import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/storage_keys.dart';
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

  @override
  State<StaffPresentWidget> createState() => _StaffPresentWidgetState();
}

class _StaffPresentWidgetState extends State<StaffPresentWidget> {
 List<String> staffList = const <String>[];
 String? selectedStaff;
 bool clickToSign = false;
 final List<String> _fetchedStaffNames = [];
 bool _loadingStaffs = false;
 late final CacheManager _cacheManager;

  @override
  void initState(){
    super.initState();
    _cacheManager = CacheManager(serviceLocator<StorageService>());
    _rebuildStaffSelection();
    clickToSign = widget.isAlreadySigned;
    _loadStaffNames();
  }

  @override
  void didUpdateWidget(StaffPresentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staffName.trim() != widget.staffName.trim()) {
      setState(_rebuildStaffSelection);
    }
    if (oldWidget.isAlreadySigned != widget.isAlreadySigned) {
      setState(() {
        clickToSign = widget.isAlreadySigned;
      });
    }
  }

  void _rebuildStaffSelection() {
    final name = widget.staffName.trim();
    final unique = <String>{};
    final ordered = <String>[];
    void addName(String value) {
      final v = value.trim();
      if (v.isEmpty) return;
      if (unique.add(v.toLowerCase())) ordered.add(v);
    }
    addName(name);
    for (final n in _fetchedStaffNames) {
      addName(n);
    }
    if (ordered.isEmpty) {
      addName('Staff');
    }
    staffList = [
      ...ordered,
    ];
    if (widget.prefillWithStaffName && name.isNotEmpty) {
      selectedStaff = staffList.firstWhere(
        (s) => s.toLowerCase() == name.toLowerCase(),
        orElse: () => name,
      );
      if (!staffList.any((s) => s.toLowerCase() == selectedStaff!.toLowerCase())) {
        staffList = [selectedStaff!, ...staffList];
      }
      return;
    }
    final current = (selectedStaff ?? '').trim();
    if (current.isNotEmpty &&
        staffList.any((s) => s.toLowerCase() == current.toLowerCase())) {
      selectedStaff = staffList.firstWhere(
        (s) => s.toLowerCase() == current.toLowerCase(),
      );
      return;
    }
    selectedStaff = staffList.first;
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

      final cacheKey = CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'list',
        identifier: '${org}_$school',
      );

      // Fast path: load cached staff names.
      try {
        final cached = await _cacheManager.loadCache(cacheKey);
        final cachedNames = cached?['names'];
        if (cachedNames is List && cachedNames.isNotEmpty) {
          _fetchedStaffNames
            ..clear()
            ..addAll(
              cachedNames
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(),
            );
          if (mounted) setState(_rebuildStaffSelection);
        }
      } catch (_) {}

      final useCase = serviceLocator<GetStaffPageUseCase>();
      final page = await useCase(
        organizationCode: org,
        schoolCode: school,
        page: 0,
        size: 300,
        status: 'ACTIVE',
      );
      _fetchedStaffNames
        ..clear()
        ..addAll(
          page.items
              .map((e) => e.name.trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
        );
      if (!mounted) return;
      await _cacheManager.saveCache(cacheKey, {
        'names': List<String>.from(_fetchedStaffNames),
      });
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
        if (widget.incidentActivity && clickToSign)
          Container(
            constraints: BoxConstraints(minHeight: 60),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFB1AFE9).withOpacity(0.102),
              //color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                selectedStaff!,
                style: TextStyle(
                  fontFamily: 'MervaleScript',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff573353),
                  //height: 19 / 14,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
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
