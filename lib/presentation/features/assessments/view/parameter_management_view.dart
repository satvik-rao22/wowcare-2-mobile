import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_access.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_confirm_dialog.dart';
import 'package:wowcare/presentation/features/assessments/widgets/parameter_form_sheets.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Parameter Management (PRD §9–§11): Domain → Subdomain → Milestone accordion
/// with CRUD for Org/School Admin and read-only access for Staff (US-PM-07).
class ParameterManagementView extends StatelessWidget {
  const ParameterManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();
    final canManage = AssessmentAccess.canManageParameters(roles);
    final cubit = context.read<AssessmentsCubit>();

    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final domains = state.activeDomains;
        final width = MediaQuery.sizeOf(context).width;
        return ListView(
          padding: AssessmentUi.bodyPadding(width),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Assessment Domains',
                      style: AssessmentUi.sectionTitleStyle(width)),
                ),
                if (canManage)
                  _GradientButton(
                    icon: Icons.add,
                    label: 'Add Domain',
                    onPressed: () => _addDomain(context, cubit, state),
                  ),
              ],
            ),
            if (!canManage)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You have read-only access to the assessment framework.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
              ),
            const SizedBox(height: 12),
            if (domains.isEmpty)
              _EmptyState(canManage: canManage)
            else
              ...domains.map((d) => _DomainCard(
                    domain: d,
                    canManage: canManage,
                    state: state,
                    cubit: cubit,
                  )),
          ],
        );
      },
    );
  }

  Future<void> _addDomain(
    BuildContext context,
    AssessmentsCubit cubit,
    AssessmentsState state,
  ) async {
    final draft = await DomainFormSheet.show(context, classrooms: state.classrooms);
    if (draft == null) return;
    final ok = await cubit.saveDomain(draft);
    if (context.mounted) _toast(context, ok, 'Domain saved');
  }
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.domain,
    required this.canManage,
    required this.state,
    required this.cubit,
  });

  final AssessmentDomain domain;
  final bool canManage;
  final AssessmentsState state;
  final AssessmentsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final accent = AssessmentUi.domainColor(domain.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_tree_rounded, size: 19, color: accent),
          ),
          title: Text(domain.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14.5)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CountChip(
                    label:
                        '${domain.activeSubdomains.length} subdomains'),
                _CountChip(
                    label: '${domain.activeMilestoneCount} milestones'),
                ..._classroomBadges(domain.assignedClassrooms),
              ],
            ),
          ),
          trailing: canManage
              ? _RowActions(
                  onEdit: () => _editDomain(context),
                  onDeactivate: () => _deactivateDomain(context),
                )
              : null,
          children: [
            if (domain.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(domain.description,
                      style: TextStyle(color: Colors.grey.shade700)),
                ),
              ),
            if (canManage)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: accent),
                  onPressed: () => _addSubdomain(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Subdomain'),
                ),
              ),
            ...domain.activeSubdomains.map((s) => _SubdomainTile(
                  domain: domain,
                  subdomain: s,
                  canManage: canManage,
                  state: state,
                  cubit: cubit,
                  accent: accent,
                )),
            if (domain.activeSubdomains.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('No subdomains yet.',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _classroomBadges(List<String> codes) =>
      _classroomBadgesFor(codes, state);

  Future<void> _editDomain(BuildContext context) async {
    final draft = await DomainFormSheet.show(context,
        initial: domain, classrooms: state.classrooms);
    if (draft == null) return;
    final ok = await cubit.saveDomain(draft);
    if (context.mounted) _toast(context, ok, 'Domain updated');
  }

  Future<void> _deactivateDomain(BuildContext context) async {
    final confirmed = await AssessmentConfirmDialog.show(
      context,
      title: 'Deactivate domain?',
      message:
          'Are you sure you want to deactivate this domain? This action will hide it from active views. Historical assessment data is preserved.',
    );
    if (!confirmed) return;
    final ok = await cubit.deactivateDomain(domain.id);
    if (context.mounted) _toast(context, ok, 'Domain deactivated');
  }

  Future<void> _addSubdomain(BuildContext context) async {
    final draft = await SubdomainFormSheet.show(context,
        domainId: domain.id, classrooms: state.classrooms);
    if (draft == null) return;
    final ok = await cubit.saveSubdomain(draft);
    if (context.mounted) _toast(context, ok, 'Subdomain saved');
  }
}

class _SubdomainTile extends StatelessWidget {
  const _SubdomainTile({
    required this.domain,
    required this.subdomain,
    required this.canManage,
    required this.state,
    required this.cubit,
    required this.accent,
  });

  final AssessmentDomain domain;
  final AssessmentSubdomain subdomain;
  final bool canManage;
  final AssessmentsState state;
  final AssessmentsCubit cubit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          leading: Icon(Icons.subdirectory_arrow_right_rounded,
              size: 18, color: accent),
          title: Text(subdomain.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _CountChip(
                    label: '${subdomain.activeMilestones.length} milestones'),
                ..._classroomBadgesFor(subdomain.assignedClassrooms, state),
              ],
            ),
          ),
          trailing: canManage
              ? _RowActions(
                  onEdit: () => _edit(context),
                  onDeactivate: () => _deactivate(context),
                )
              : null,
          children: [
            if (canManage)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: accent),
                  onPressed: () => _addMilestone(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Milestone'),
                ),
              ),
            ...subdomain.activeMilestones.map((m) => _MilestoneRow(
                  domain: domain,
                  subdomain: subdomain,
                  milestone: m,
                  canManage: canManage,
                  state: state,
                  cubit: cubit,
                )),
            if (subdomain.activeMilestones.isEmpty)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text('No milestones yet.',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final draft = await SubdomainFormSheet.show(context,
        domainId: domain.id, initial: subdomain, classrooms: state.classrooms);
    if (draft == null) return;
    final ok = await cubit.saveSubdomain(draft);
    if (context.mounted) _toast(context, ok, 'Subdomain updated');
  }

  Future<void> _deactivate(BuildContext context) async {
    final confirmed = await AssessmentConfirmDialog.show(
      context,
      title: 'Deactivate subdomain?',
      message: 'Are you sure you want to deactivate this subdomain?',
    );
    if (!confirmed) return;
    final ok = await cubit.deactivateSubdomain(subdomain.id);
    if (context.mounted) _toast(context, ok, 'Subdomain deactivated');
  }

  Future<void> _addMilestone(BuildContext context) async {
    final draft = await MilestoneFormSheet.show(context,
        domainId: domain.id,
        subdomainId: subdomain.id,
        classrooms: state.classrooms);
    if (draft == null) return;
    final ok = await cubit.saveMilestone(draft);
    if (context.mounted) _toast(context, ok, 'Milestone saved');
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.domain,
    required this.subdomain,
    required this.milestone,
    required this.canManage,
    required this.state,
    required this.cubit,
  });

  final AssessmentDomain domain;
  final AssessmentSubdomain subdomain;
  final AssessmentMilestone milestone;
  final bool canManage;
  final AssessmentsState state;
  final AssessmentsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final hasClassrooms = milestone.assignedClassrooms.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(milestone.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (milestone.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(milestone.description,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ),
                  ],
                ),
              ),
              if (canManage)
                _RowActions(
                  onEdit: () => _edit(context),
                  onDeactivate: () => _deactivate(context),
                  onAssign: () => _assign(context),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: hasClassrooms
                ? milestone.assignedClassrooms
                    .map((code) => _ClassroomChip(
                          label: state.classroomByCode(code)?.name ?? code,
                        ))
                    .toList()
                : const [_WarningChip(label: 'No classrooms assigned')],
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final draft = await MilestoneFormSheet.show(context,
        domainId: domain.id,
        subdomainId: subdomain.id,
        initial: milestone,
        classrooms: state.classrooms);
    if (draft == null) return;
    final ok = await cubit.saveMilestone(draft);
    if (context.mounted) _toast(context, ok, 'Milestone updated');
  }

  Future<void> _deactivate(BuildContext context) async {
    final confirmed = await AssessmentConfirmDialog.show(
      context,
      title: 'Deactivate milestone?',
      message: 'Are you sure you want to deactivate this milestone?',
    );
    if (!confirmed) return;
    final ok = await cubit.deactivateMilestone(milestone.id);
    if (context.mounted) _toast(context, ok, 'Milestone deactivated');
  }

  Future<void> _assign(BuildContext context) async {
    final codes = await ClassroomAssignmentSheet.show(context,
        milestone: milestone, classrooms: state.classrooms);
    if (codes == null) return;
    final ok = await cubit.updateMilestoneClassrooms(milestone.id, codes);
    if (context.mounted) _toast(context, ok, 'Classroom assignment updated');
  }
}

// ----------------------------------------------------------------- shared

List<Widget> _classroomBadgesFor(List<String> codes, AssessmentsState state) {
  final allCodes = state.classrooms.map((c) => c.code).toSet();
  if (codes.isNotEmpty &&
      allCodes.isNotEmpty &&
      allCodes.every((c) => codes.contains(c))) {
    return const [_ClassroomChip(label: 'Applies to all classrooms')];
  }
  if (codes.isEmpty) return const [];
  return codes
      .map((c) => _ClassroomChip(label: state.classroomByCode(c)?.name ?? c))
      .toList();
}

void _toast(BuildContext context, bool ok, String successMessage) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ok ? successMessage : 'Something went wrong. Try again.'),
      backgroundColor: ok ? AppColors.successColor : AppColors.errorColor,
    ),
  );
}

enum _RowAction { assign, edit, deactivate }

/// A single roomy overflow ("kebab") menu replacing the old cluster of tiny
/// 18px icon buttons — one comfortable tap target that declutters the row and
/// reveals Edit / Assign / Deactivate in a sheet-style popup.
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onEdit,
    required this.onDeactivate,
    this.onAssign,
  });

  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RowAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: PopupMenuPosition.under,
      onSelected: (action) {
        switch (action) {
          case _RowAction.assign:
            onAssign?.call();
          case _RowAction.edit:
            onEdit();
          case _RowAction.deactivate:
            onDeactivate();
        }
      },
      itemBuilder: (context) => [
        if (onAssign != null)
          const PopupMenuItem(
            value: _RowAction.assign,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.meeting_room_outlined),
              title: Text('Assign classrooms'),
            ),
          ),
        const PopupMenuItem(
          value: _RowAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        const PopupMenuItem(
          value: _RowAction.deactivate,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: AppColors.errorColor),
            title: Text('Deactivate',
                style: TextStyle(color: AppColors.errorColor)),
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.themeColor, fontWeight: FontWeight.w600)),
    );
  }
}

class _ClassroomChip extends StatelessWidget {
  const _ClassroomChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8))),
    );
  }
}

class _WarningChip extends StatelessWidget {
  const _WarningChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 12, color: Color(0xFFB91C1C)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.buildPrimaryGradient(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            canManage
                ? 'No domains yet. Tap "Add Domain" to build your framework.'
                : 'No assessment framework has been set up for your classrooms yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
