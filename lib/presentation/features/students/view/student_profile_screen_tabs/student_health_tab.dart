import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:wowcare/presentation/features/students/view/student_health_tab_cards/student_health_tab_card.dart';
import 'package:wowcare/app/theme/colors.dart';

import '../../../../../shared/common/widgets/custom_toggle.dart';
import '../student_health_tab_cards/student_dates_tab_card.dart';
import '../student_health_tab_cards/student_immunization_tab_card.dart';
import '../student_health_tab_cards/student_physician_tab_card.dart';


class StudentHealthTab extends StatefulWidget {
  const StudentHealthTab({
    super.key,
    this.initialTabIndex = 0,
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
  });

  final int initialTabIndex;
  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;


  @override
  State<StudentHealthTab> createState() => _StudentHealthTabState();
}

class _StudentHealthTabState extends State<StudentHealthTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _healthScrollController = ScrollController();
  final ScrollController _physicianScrollController = ScrollController();
  final ScrollController _datesScrollController = ScrollController();
  final ScrollController _immunizationScrollController = ScrollController();
  bool _isImmunizationExempt = false;


  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }




  @override
  void dispose() {
    _tabController.dispose();
    _healthScrollController.dispose();
    _physicianScrollController.dispose();
    _datesScrollController.dispose();
    _immunizationScrollController.dispose();
    super.dispose();
  }

  Tab _buildTab({
    required String label,
    required Color color,
    //required double width,
  }) {
    return Tab(
      child: Container(
        //width: width,
        padding: EdgeInsets.symmetric(horizontal: 4.w,),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Text(
            label,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isImmunizationTab = _tabController.index == 3;
    return Column(
      children: [
        if (isImmunizationTab) ...[
          SizedBox(height: 10,),
          CustomSectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomToggle(
                        key: ValueKey(_isImmunizationExempt),
                        label: '',
                        isToggled: _isImmunizationExempt,
                        onToggle: (v) => setState(() => _isImmunizationExempt = v),
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: const Text(
                          'Exempt students from immunizations',
                          maxLines: 3,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff573353),
                            height: 16 / 13,
                          ),
                        ),
                      ),
                      SizedBox(width: 10,),
                    ],
                  ),
                ),

                Flexible(
                  child: Container(
                    height: 35,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _isImmunizationExempt
                          ? const LinearGradient(
                              colors: [Color(0xFFC9C5CE), Color(0xFFB8B3BE)],
                            )
                          : AppColors.buildPrimaryGradient(),
                    ),
                    child: TextButton(
                      onPressed: _isImmunizationExempt ? null : () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        _isImmunizationExempt ? 'Reminder Disabled' : 'Send Reminder',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 16 / 16,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Transform.translate(
          offset: const Offset(0, 4),
          child: TabBar(
            isScrollable: true,
            padding: EdgeInsets.zero,
            tabAlignment: TabAlignment.start,
            controller: _tabController,
            dividerHeight: 0,
            indicator: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(
                color: AppColors.classroomStudentTabColor
                    .withValues(alpha: 1),
              ),
            ),
            labelStyle: TextTheme.of(context).titleSmall!.copyWith(
              color: AppColors.primaryColor,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextTheme.of(context)
                .titleSmall!
                .copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            labelPadding: const EdgeInsets.all(0),
            indicatorPadding: _tabController.index == 0
                ? const EdgeInsets.only(right: 4)
                : _tabController.index == 1
                ? const EdgeInsets.symmetric(horizontal: 2)
                : _tabController.index == 2
                ? const EdgeInsets.symmetric(horizontal: 2)
                : const EdgeInsets.only(left: 4),
            splashFactory: NoSplash.splashFactory,
            tabs: [
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _buildTab(
                  //width: 80,
                  label: 'Health',
                  color: AppColors.classroomStudentTabColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildTab(
                  //width: 90,
                  label: 'Physician',
                  color: AppColors.classroomStaffTabColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildTab(
                  //width: 200,
                  label: 'Physical Examination Dates',
                  color: AppColors.classroomNotesTabColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: _buildTab(
                  //width: 120,
                  label: 'Immunization',
                  color: Color(0x66EAD6FF),
                ),
              ),
            ],


          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              StudentHealthTabCard(
                scrollController: _healthScrollController,
                studentCode: widget.studentCode,
              ),
              StudentPhysicianTabCard(
                scrollController: _physicianScrollController,
                name: widget.name,
                classroom: widget.classroom,
                studentCode: widget.studentCode,
              ),
              StudentDatesTabCard(
                scrollController: _datesScrollController,
                name: widget.name,
                classroom: widget.classroom,
                studentCode: widget.studentCode,
              ),
              StudentImmunizationTabCard(
                scrollController: _immunizationScrollController,
                name: widget.name,
                classroom: widget.classroom,
                studentCode: widget.studentCode,
              ),
            ],
          ),
        ),
      ],




    );
  }
}

class CustomSectionCard extends StatelessWidget {
  const CustomSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.backgroundColor,
    this.minHeight,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      constraints: BoxConstraints(
        minHeight: minHeight ?? 0,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor ?? AppColors.cardColor,
      ),
      child: child,
    );
  }
}

