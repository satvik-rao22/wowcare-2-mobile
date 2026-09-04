import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/view/classroom_profile_body.dart';
import 'package:wowcare/presentation/features/assessments/view/classrooms_list_body.dart';
import 'package:wowcare/presentation/features/assessments/view/framework_body.dart';
import 'package:wowcare/presentation/features/assessments/view/school_dashboard_body.dart';
import 'package:wowcare/presentation/features/assessments/view/student_stepper_body.dart';
import 'package:wowcare/presentation/features/assessments/view/students_list_body.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_shell_chrome.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Entry point and self-contained shell for the redesigned Assessments module.
///
/// Unlike a typical screen this hosts its own four-tab bottom navigation and
/// performs all drill-down navigation *in place* (student stepper, classroom
/// roll-up, framework levels) rather than pushing routes — mirroring the
/// standalone redesign. The app-wide navigation bar is hidden while inside.
class AssessmentsHomeScreen extends StatefulWidget {
  const AssessmentsHomeScreen({super.key});

  static const String routeName = '/dashboard/assessments';

  @override
  State<AssessmentsHomeScreen> createState() => _AssessmentsHomeScreenState();
}

class _AssessmentsHomeScreenState extends State<AssessmentsHomeScreen> {
  AssessmentSection _section = AssessmentSection.students;

  // Drill-down targets (null = at the list level for that section).
  String? _studentCode;
  String? _classroomCode;
  String? _fwDomainId;
  String? _fwSubdomainId;

  void _selectSection(AssessmentSection section) {
    setState(() {
      _section = section;
      _studentCode = null;
      _classroomCode = null;
      _fwDomainId = null;
      _fwSubdomainId = null;
    });
  }

  void _back() {
    setState(() {
      if (_studentCode != null) {
        _studentCode = null;
      } else if (_classroomCode != null) {
        _classroomCode = null;
      } else if (_fwSubdomainId != null) {
        _fwSubdomainId = null;
      } else if (_fwDomainId != null) {
        _fwDomainId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();
    final roleLabel = roles.role == 'admin' ? 'Admin' : 'Teacher';
    final canManage = roles.role == 'admin';
    final isDrilledIn = _studentCode != null ||
        _classroomCode != null ||
        _fwDomainId != null;

    return PopScope(
      // Intercept back while drilled in so it climbs one level instead of
      // leaving the module entirely; allow the pop at the list level.
      canPop: !isDrilledIn,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: GlobalScaffold(
        hasBackButton: false,
        showCustomNavigationBar: false,
        bodyPadding: EdgeInsets.zero,
        body: BlocBuilder<AssessmentsCubit, AssessmentsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: PrimaryCircularLoader());
            }
            return ColoredBox(
              color: AssessmentUi.pageBackground,
              child: SafeArea(
                bottom: false,
                child: _buildShell(context, state, roleLabel, canManage),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShell(
    BuildContext context,
    AssessmentsState state,
    String roleLabel,
    bool canManage,
  ) {
    final inStudent = _studentCode != null;
    final inClassroom = _classroomCode != null;
    final fwDeep = _section == AssessmentSection.framework && _fwDomainId != null;
    final showBottomNav = !inStudent && !inClassroom && !fwDeep;
    final showFab = _section == AssessmentSection.framework &&
        _fwDomainId == null &&
        canManage;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBottomNav)
          AssessmentTopHeader(
            title: _section.label,
            roleLabel: roleLabel,
            themeV2: state.themeV2,
            onThemeSelect: context.read<AssessmentsCubit>().setThemeV2,
          )
        else
          _buildBackBar(state, canManage),
        Expanded(child: _buildBody(state)),
        if (showBottomNav)
          AssessmentBottomNav(current: _section, onSelect: _selectSection),
      ],
    );

    if (!showFab) return column;
    return Stack(
      children: [
        Positioned.fill(child: column),
        Positioned(
          right: 18,
          bottom: 92,
          child: _AddDomainFab(
            onTap: () => FrameworkActions.addDomain(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBackBar(AssessmentsState state, bool canManage) {
    if (_studentCode != null) {
      final student = state.studentByCode(_studentCode!);
      return AssessmentBackBar(
        title: student?.name ?? 'Assessment',
        subtitle: 'Assessment',
        onBack: _back,
      );
    }
    if (_classroomCode != null) {
      final classroom = state.classroomByCode(_classroomCode!);
      return AssessmentBackBar(
        title: classroom?.name ?? 'Classroom',
        subtitle: 'Classroom roll-up',
        onBack: _back,
      );
    }
    // Parameters drill-down.
    final domain =
        _fwDomainId == null ? null : state.domainById(_fwDomainId!);
    final matchingSubs = _fwSubdomainId == null || domain == null
        ? const []
        : domain.subdomains.where((s) => s.id == _fwSubdomainId).toList();
    final subdomain = matchingSubs.isEmpty ? null : matchingSubs.first;
    if (subdomain != null) {
      return AssessmentBackBar(
        title: subdomain.name,
        subtitle: domain?.name,
        onBack: _back,
        actionLabel: canManage ? 'Milestone' : null,
        onAction: canManage
            ? () => FrameworkActions.addMilestone(
                  context,
                  domainId: domain!.id,
                  subdomainId: subdomain.id,
                )
            : null,
      );
    }
    return AssessmentBackBar(
      title: domain?.name ?? 'Parameters',
      subtitle: 'Subdomains',
      onBack: _back,
      actionLabel: canManage ? 'Subdomain' : null,
      onAction: canManage && domain != null
          ? () => FrameworkActions.addSubdomain(context, domainId: domain.id)
          : null,
    );
  }

  Widget _buildBody(AssessmentsState state) {
    if (_studentCode != null) {
      return StudentStepperBody(
        key: ValueKey('stepper-$_studentCode-${state.period.start}'),
        studentCode: _studentCode!,
        onExit: _back,
      );
    }
    switch (_section) {
      case AssessmentSection.students:
        return StudentsListBody(
          onOpenStudent: (code) => setState(() => _studentCode = code),
        );
      case AssessmentSection.classrooms:
        if (_classroomCode != null) {
          return ClassroomProfileBody(classroomCode: _classroomCode!);
        }
        return ClassroomsListBody(
          onOpenClassroom: (code) => setState(() => _classroomCode = code),
        );
      case AssessmentSection.school:
        return const SchoolDashboardBody();
      case AssessmentSection.framework:
        return FrameworkBody(
          domainId: _fwDomainId,
          subdomainId: _fwSubdomainId,
          onOpenDomain: (id) => setState(() => _fwDomainId = id),
          onOpenSubdomain: (id) => setState(() => _fwSubdomainId = id),
        );
    }
  }
}

/// Gradient extended FAB for adding a domain (Parameters tab, admins only).
class _AddDomainFab extends StatelessWidget {
  const _AddDomainFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AssessmentUi.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AssessmentUi.accent.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const SizedBox(
            height: 52,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Add Domain',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
