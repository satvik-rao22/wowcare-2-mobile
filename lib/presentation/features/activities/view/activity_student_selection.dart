import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../shared/common/widgets/custom_search_bar.dart';

class ActivityStudentSelection extends StatefulWidget {
  const ActivityStudentSelection({super.key});
  final bool showLoading = false;

  @override
  State<ActivityStudentSelection> createState() => _ActivityStudentSelectionState();
}

class _ActivityStudentSelectionState extends State<ActivityStudentSelection> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClassroom;
  List<String> _selectedTags = [];
  final List<String> _classroomOptions = ['1-Blue D', '3-Orange-D', '2-Red A'];
  final List<String> _tagOptions =  [
  '5 Days',
  'Full Day',
  'Photo Permission',
  'Vegetarian',
  'First Aid',
  'Allergy',
  'Pickup Authorized',
  'Medication',
  'Half Day',
  'Boy',
  'Girl',
  ];

  @override
  void initState(){
    super.initState();
    //_applyFilters();
    //_searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    //_searchController.removeListener(_applyFilters);
    //_searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true,),
      body: Stack(
        children: [
          Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Activity',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff573353),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
              Expanded(
                child: Container(
                  width: responsive.containerWidth,
                  margin: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  padding: EdgeInsets.all(
                    responsive.isTablet ? 32.0 : 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        responsive.isTablet ? 30.0 : 20.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Select Students',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff573353),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: 'Search Students',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10,),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCustomDropdown(
                              'Classroom',
                              _classroomOptions,
                              _selectedClassroom,
                                  (v) => setState(() {
                                _selectedClassroom = v;
                              }),
                            ),
                          ),
                           const SizedBox(width: 8),
                          Expanded(
                            child: CustomMultiSelectDropdown(
                              hintText: 'Tags',
                              items: _tagOptions,
                              selectedItems: _selectedTags,
                              gapHeight: 40,
                              onChanged: (selectedItems) {
                              },
                            ),
                          ),



                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          )
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildCustomDropdown(
      String hintText,
      List<String> items,
      String? selectedItem,
      ValueChanged<String?> onSelect, {
        bool isRequired = false,
        double? height = null
      }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      items: items,
      height: height,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: "Manrope",
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      //fieldHeight: responsive.isTablet ? 64.0 : 56.0,
      fieldHeight: 40,
      selectedTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: const Color(0xff573353),
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 16.0 : 12.0,
        vertical: responsive.isTablet ? 16.0 : 12.0,
      ),
    );
  }

  // Widget _buildShimmer() {
  //   return GridView.builder(
  //       padding: EdgeInsets.zero,
  //       physics: const NeverScrollableScrollPhysics(),
  //       shrinkWrap: true,
  //       itemCount: widget.sections.length,
  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6),
  //       itemBuilder: (context, index) {
  //         return Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(widget.sections[index].label, style: TextStyle(color: AppColors.primaryColor, fontSize: 13),),
  //             const SizedBox(height: 8,),
  //             const ShimmerLoader(height: 40,)
  //           ],
  //         );
  //       }
  //   );
  // }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
              ),
              child: Padding(
                  padding: EdgeInsets.all(1),
                  child: Container(
                    //alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
                    ),
                    child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          overlayColor: Colors.transparent,
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds){
                            return AppColors.buildPrimaryGradient().createShader(bounds);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.buttonFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    )
                  ),
              )
            ),
          ),
          const SizedBox(width: 10,),
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
              ),
              child: TextButton(
                onPressed: null,
                style: TextButton.styleFrom(
                  overlayColor: Colors.transparent,
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



}
