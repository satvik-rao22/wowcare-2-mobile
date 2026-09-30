import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/presentation/features/students/view_model/student_health_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_health_tab_cards/student_health_tab_card.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
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

  /// Owned here (not by the card) so the exempt-all toggle above the TabBar and
  /// the immunization list inside it read the same records.
  final StudentHealthCubit _immunizationCubit =
      serviceLocator<StudentHealthCubit>();

  /// True only while the bulk PATCHes are in flight — keeps the toggle showing
  /// ON before the reload lands, and blocks a second run.
  bool _exemptAllInProgress = false;

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
    _immunizationCubit.close();
    super.dispose();
  }

  /// The toggle is a mirror of the data, not its own switch: it reads ON only
  /// once every record is EXEMPT, which is also why it can never be turned back
  /// off — nothing in the UI writes any other status to the whole list.
  bool _allRecordsExempt(StudentHealthState state) =>
      state.immunizations.isNotEmpty &&
      state.immunizations.every(
        (r) => r.status.trim().toUpperCase() == 'EXEMPT',
      );

  Future<void> _confirmExemptAllImmunizations() async {
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ExemptAllConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _exemptAllInProgress = true);
    try {
      await _immunizationCubit.exemptAllImmunizations(studentCode: studentCode);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.allImmunizationsMarkedExempt,
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.logApiError(e.toString());
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _exemptAllInProgress = false);
    }
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
          child: ColoredBox(color: AppColors.pageBackgroundColor),
        ),
        Column(
          children: [
            if (isImmunizationTab && canEditStudentData) ...[
              SizedBox(height: AppSpacing.s10),
              BlocBuilder<StudentHealthCubit, StudentHealthState>(
                bloc: _immunizationCubit,
                builder: (context, state) {
                  final bool isExempt =
                      _exemptAllInProgress || _allRecordsExempt(state);
                  // One-way switch: tappable only while there is still
                  // something to exempt.
                  final bool canExemptAll =
                      !isExempt &&
                      !state.immunizationsLoading &&
                      state.immunizations.isNotEmpty;
                  return CustomSectionCard(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: canExemptAll
                          ? _confirmExemptAllImmunizations
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomToggle(
                            key: ValueKey(isExempt),
                            label: '',
                            isToggled: isExempt,
                            // Driven by the confirm flow on the row, never by
                            // its own tap — so a cancelled dialog can't leave
                            // the knob flipped ahead of the data.
                            enabled: false,
                            onToggle: (_) {},
                          ),
                          SizedBox(width: AppSpacing.s10),
                          Expanded(
                            child: Text(
                              StudentStrings.exemptStudentsFromImmunizations,
                              maxLines: 3,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.primaryColor,
                                height: 16 / 13,
                              ),
                            ),
                          ),
                          if (_exemptAllInProgress) ...[
                            SizedBox(width: AppSpacing.s10),
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
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
                    healthCubit: _immunizationCubit,
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

/// Pops `true` only when the user explicitly confirms. Exempting the whole list
/// cannot be undone from this screen, so dismissing by tapping outside is off —
/// Cancel and the close icon are the only ways out.
class _ExemptAllConfirmationDialog extends StatelessWidget {
  const _ExemptAllConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: AppColors.studentLavenderTint,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    StudentStrings.confirmation,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.close,
                    size: AppDimensions.iconSm,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Text(
              StudentStrings.confirmExemptAllImmunizations,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.studentMutedText,
                height: 20 / 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: CustomButtonLayout(
              isForm: false,
              cancelButtonLabel: StudentStrings.cancel,
              confirmButtonLabel: StudentStrings.yesExemptAll,
              onPressedCancel: () => Navigator.of(context).pop(false),
              onPressedConfirm: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
  }
}
