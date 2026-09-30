import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';

/// Page size used to fill the assignee picker. One round trip covers all but
/// the largest schools; anything beyond is paged in by [loadAssignableStaff].
const int _assigneePickerPageSize = 100;

/// Safety valve against a server that never shortens a page.
const int _assigneePickerMaxExtraPages = 20;

/// Loads the assignable-staff roster for the Task form's assignee picker.
///
/// Deliberately **unscoped**: every task-capable persona — staff and teacher
/// personas included — may assign a task to any ACTIVE staff member. A task is
/// not a classroom-bound artefact, so a teacher must still be able to hand work
/// to the front desk, a floater, or a colleague in another room.
///
/// An earlier revision read PRD §5.2 ("assign to staff in allowed classes
/// only") as a client-side filter and passed the persona's
/// `allowedClassroomCodes` as the staff-list `classCodes` filter. In practice
/// that left a staff persona's picker showing only the signed-in user, so it is
/// gone. Do not reintroduce a client-side classroom filter here: if this
/// boundary is ever wanted, it belongs to the staff-list API, which owns the
/// classroom membership the client only caches.
///
/// The picker is single-shot — no lazy loading, and its search box filters
/// locally over what it was given — so the whole roster is paged in up front.
/// [StaffCubit] already defaults to ACTIVE-only, which is the picker's rule
/// (PRD BR-ATT-01 / FR-TK-02).
Future<void> loadAssignableStaff(StaffCubit cubit) async {
  cubit.setPageSize(_assigneePickerPageSize);
  await cubit.loadInitial();

  var extraPages = 0;
  while (!cubit.isClosed &&
      cubit.state.hasMore &&
      extraPages < _assigneePickerMaxExtraPages) {
    final loaded = cubit.state.items.length;
    await cubit.loadNextPage();
    // A page that added nothing means the request failed or the server keeps
    // claiming `hasMore` — stop rather than spin (the form may also have been
    // popped mid-load, which closes the cubit and drops every result).
    if (cubit.state.items.length == loaded) break;
    extraPages++;
  }
}
