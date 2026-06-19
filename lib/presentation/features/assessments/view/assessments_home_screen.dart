import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_access.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/view/classroom_assessment_list_view.dart';
import 'package:wowcare/presentation/features/assessments/view/parameter_management_view.dart';
import 'package:wowcare/presentation/features/assessments/view/school_assessment_view.dart';
import 'package:wowcare/presentation/features/assessments/view/student_assessment_list_view.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Entry point for the Assessments module. Hosts the role-gated tabs:
/// Parameters · Students · Classrooms · School. Fully responsive — the tab bar
/// scrolls on phones and content is width-capped/centred on large web displays.
class AssessmentsHomeScreen extends StatefulWidget {
  const AssessmentsHomeScreen({super.key});

  static const String routeName = '/dashboard/assessments';

  @override
  State<AssessmentsHomeScreen> createState() => _AssessmentsHomeScreenState();
}

class _AssessmentsHomeScreenState extends State<AssessmentsHomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _controller;
  int _tabCount = 0;

  List<_AssessmentTab> _tabsFor(RoleCubit roles) {
    return <_AssessmentTab>[
      const _AssessmentTab(
        label: 'Parameters',
        icon: Icons.account_tree_outlined,
        view: ParameterManagementView(),
      ),
      if (AssessmentAccess.canEnterAssessments(roles))
        const _AssessmentTab(
          label: 'Students',
          icon: Icons.face_outlined,
          view: StudentAssessmentListView(),
        ),
      if (AssessmentAccess.canViewRollups(roles)) ...const [
        _AssessmentTab(
          label: 'Classrooms',
          icon: Icons.meeting_room_outlined,
          view: ClassroomAssessmentListView(),
        ),
        _AssessmentTab(
          label: 'School',
          icon: Icons.school_outlined,
          view: SchoolAssessmentView(),
        ),
      ],
    ];
  }

  void _ensureController(int count) {
    if (_controller == null || _tabCount != count) {
      _controller?.dispose();
      _controller = TabController(length: count, vsync: this);
      _tabCount = count;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();
    final tabs = _tabsFor(roles);
    _ensureController(tabs.length);

    return GlobalScaffold(
      hasBackButton: false,
      showCustomNavigationBar: true,
      bodyPadding: EdgeInsets.zero,
      body: BlocBuilder<AssessmentsCubit, AssessmentsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: PrimaryCircularLoader());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.assessment_outlined,
                        color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Assessments',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (state.errorMessage != null)
                      Tooltip(
                        message: state.errorMessage!,
                        child: const Icon(Icons.error_outline,
                            color: AppColors.errorColor, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              TabBar(
                controller: _controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.themeColor,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppColors.themeColor,
                tabs: tabs
                    .map((t) => Tab(
                          icon: Icon(t.icon, size: 18),
                          text: t.label,
                          iconMargin: const EdgeInsets.only(bottom: 2),
                        ))
                    .toList(),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _controller,
                  children: tabs
                      .map((t) => _ResponsiveBody(child: t.view))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Caps content width and centres it on large displays so dashboards stay
/// readable; full-bleed on phones/tablets.
class _ResponsiveBody extends StatelessWidget {
  const _ResponsiveBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = AssessmentUi.contentMaxWidth(constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: child,
          ),
        );
      },
    );
  }
}

class _AssessmentTab {
  const _AssessmentTab({
    required this.label,
    required this.icon,
    required this.view,
  });

  final String label;
  final IconData icon;
  final Widget view;
}
