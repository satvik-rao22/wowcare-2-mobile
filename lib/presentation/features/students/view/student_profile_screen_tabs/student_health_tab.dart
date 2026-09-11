import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_health_tab_cards/student_health_tab_card.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';

import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/students/view/student_health_tab_cards/student_dates_tab_card.dart';
import 'package:wowcare/presentation/features/students/view/student_health_tab_cards/student_immunization_tab_card.dart';
import 'package:wowcare/presentation/features/students/view/student_health_tab_cards/student_physician_tab_card.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

class StudentHealthTab extends StatefulWidget {
  const StudentHealthTab({
    super.key,
    this.initialTabIndex = 0,
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    this.canEdit = false,
    this.onHealthChanged,
  });

  final int initialTabIndex;
  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;

  /// Whether the current persona may edit health records (resolved from the
  /// school's student-settings by the parent screen).
  final bool canEdit;
  final VoidCallback? onHealthChanged;

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
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.md),
          ),
        ),
        child: Center(child: Text(label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final canEditStudentData = ModuleAccess.mayWrite(
      role,
      AppAccessModules.student,
    );
    final bool isImmunizationTab = _tabController.index == 3;
    return Stack(
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
            if (isImmunizationTab && canEditStudentData) ...[
              SizedBox(height: AppSpacing.s10),
              CustomSectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomToggle(
                      key: ValueKey(_isImmunizationExempt),
                      label: '',
                      isToggled: _isImmunizationExempt,
                      onToggle: (v) {
                        setState(() => _isImmunizationExempt = v);
                      },
                    ),
                    SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: Text(
                        StudentStrings.exemptStudentsFromImmunizations,
                        maxLines: 3,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: Fonts.manrope,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryColor,
                          height: 16 / 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVLg,
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
                    top: Radius.circular(AppRadius.md),
                  ),
                  border: Border.all(
                    color: AppColors.classroomStudentTabColor.withValues(
                      alpha: 1,
                    ),
                  ),
                ),
                labelStyle: TextTheme.of(context).titleSmall!.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 14,
                ),
                unselectedLabelStyle: TextTheme.of(context).titleSmall!
                    .copyWith(
                      color: AppColors.primaryColor.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                labelPadding: const EdgeInsets.all(AppSpacing.none),
                indicatorPadding: _tabController.index == 0
                    ? const EdgeInsets.only(right: AppSpacing.xxs)
                    : _tabController.index == 1
                    ? const EdgeInsets.symmetric(horizontal: AppSpacing.s2)
                    : _tabController.index == 2
                    ? const EdgeInsets.symmetric(horizontal: AppSpacing.s2)
                    : const EdgeInsets.only(left: AppSpacing.xxs),
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s2),
                    child: _buildTab(
                      //width: 80,
                      label: StudentStrings.health,
                      color: AppColors.classroomStudentTabColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2,
                    ),
                    child: _buildTab(
                      //width: 90,
                      label: StudentStrings.physician,
                      color: AppColors.classroomStaffTabColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2,
                    ),
                    child: _buildTab(
                      //width: 200,
                      label: StudentStrings.physicalExaminationDates,
                      color: AppColors.classroomNotesTabColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.s2),
                    child: _buildTab(
                      //width: 120,
                      label: StudentStrings.immunization,
                      color: AppColors.studentLavenderTint,
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
                    canEdit: widget.canEdit,
                    onHealthChanged: widget.onHealthChanged,
                  ),
                  StudentPhysicianTabCard(
                    scrollController: _physicianScrollController,
                    name: widget.name,
                    classroom: widget.classroom,
                    studentCode: widget.studentCode,
                    canEdit: widget.canEdit,
                  ),
                  StudentDatesTabCard(
                    scrollController: _datesScrollController,
                    name: widget.name,
                    classroom: widget.classroom,
                    studentCode: widget.studentCode,
                    canEdit: widget.canEdit,
                  ),
                  StudentImmunizationTabCard(
                    scrollController: _immunizationScrollController,
                    name: widget.name,
                    classroom: widget.classroom,
                    studentCode: widget.studentCode,
                    canEdit: widget.canEdit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
