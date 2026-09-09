import '../../domain/entities/regularization_request.dart';
import '../../domain/repositories/regularization_repository.dart';

/// The admin list's tabs.
///
/// §9.3 and §9.5 are the same endpoint with a `status` filter, so the admin
/// gets a pending **work queue** and an approved **history** from one call —
/// this enum just carries which combination each tab asks for.
///
/// The queue and the history want **opposite** sort orders, which is why the
/// order travels with the filter rather than being a constant: acting on the
/// longest-waiting request first is right for a queue (§9.5 documents
/// `createdAt,asc`), while history reads newest-first.
enum RegInboxFilter {
  pending,
  approved,
  all;

  String get label {
    switch (this) {
      case RegInboxFilter.pending:
        return 'Pending';
      case RegInboxFilter.approved:
        return 'Approved';
      case RegInboxFilter.all:
        return 'All';
    }
  }

  /// `null` means "no `status` param", i.e. the full history.
  RegStatus? get status {
    switch (this) {
      case RegInboxFilter.pending:
        return RegStatus.pending;
      case RegInboxFilter.approved:
        return RegStatus.approved;
      case RegInboxFilter.all:
        return null;
    }
  }

  RegSortOrder get sort {
    switch (this) {
      case RegInboxFilter.pending:
        return RegSortOrder.oldestFirst;
      case RegInboxFilter.approved:
      case RegInboxFilter.all:
        return RegSortOrder.newestFirst;
    }
  }

  /// True when rows in this tab can be selected for bulk approve. Only the
  /// pending queue is actionable; a history tab is read-only.
  bool get supportsSelection => this == RegInboxFilter.pending;

  String get emptyMessage {
    switch (this) {
      case RegInboxFilter.pending:
        return 'No pending requests';
      case RegInboxFilter.approved:
        return 'No approved requests yet';
      case RegInboxFilter.all:
        return 'No requests yet';
    }
  }
}
