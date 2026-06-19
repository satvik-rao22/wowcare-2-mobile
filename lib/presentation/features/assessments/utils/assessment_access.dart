import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Role-based access rules for the Assessments module (PRD §5).
///
/// IMPORTANT: `RoleCubit.isAdmin` returns true for BOTH 'admin' and 'staff'
/// (legacy behaviour shared with Events/Tasks). Parameter *write* access is
/// admin-only, so those checks compare `roles.role == 'admin'` directly rather
/// than using `isAdmin`.
///
/// Persona mapping for this module:
///  • 'admin'  → Org Admin / School Admin (full write).
///  • 'staff'  → Staff / Teacher (read-only parameters; scoped student scoring).
///  • 'parent' → Guardian / Parent — fully excluded this release (PRD §3.2).
abstract final class AssessmentAccess {
  const AssessmentAccess._();

  /// Whole module — navigation, screens, data — is hidden from guardians.
  static bool canAccessModule(RoleCubit roles) => !roles.isParent;

  /// Only Org/School Admin (and CWW Super Admin via impersonation, which maps
  /// to 'admin') may create/edit/deactivate Domains, Subdomains, Milestones and
  /// manage classroom assignments (PRD BR-PM-03).
  static bool canManageParameters(RoleCubit roles) => roles.role == 'admin';

  /// Staff get read-only Parameter Management (PRD US-PM-07).
  static bool canViewParameters(RoleCubit roles) => !roles.isParent;

  /// Admins and Staff/Teachers may enter/update student assessment scores.
  /// (Staff are additionally scoped to their classrooms — enforced by the data
  /// they're shown / BR-AS-02 on the backend.)
  static bool canEnterAssessments(RoleCubit roles) =>
      roles.role == 'admin' || roles.isStaff;

  /// Classroom & School roll-up dashboards are visible to admins and staff
  /// (staff read-only); never to parents (PRD §5.3).
  static bool canViewRollups(RoleCubit roles) => !roles.isParent;

  /// Whether this persona may pick any classroom (admin) vs only their
  /// assigned ones (staff). Drives the classroom selector's option set.
  static bool canSelectAnyClassroom(RoleCubit roles) => roles.role == 'admin';
}
