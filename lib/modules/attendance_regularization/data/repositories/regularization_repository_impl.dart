import '../../core/errors/reg_exceptions.dart';
import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/reg_batch_gate.dart';
import '../../domain/entities/reg_batch_result.dart';
import '../../domain/entities/reg_edit_input.dart';
import '../../domain/entities/reg_page.dart';
import '../../domain/entities/reg_raise_input.dart';
import '../../domain/entities/regularization_request.dart';
import '../../domain/repositories/regularization_repository.dart';
import '../datasources/reg_remote_datasource.dart';
import '../mappers/reg_mappers.dart';
import '../reg_context.dart';

/// Ties the datasource, the mappers and the host context together.
///
/// It owns exactly two responsibilities the layers either side must not:
///
/// 1. **Timezone resolution.** Every call resolves the school zone once and
///    hands it to the mappers, so wall-clock ⇄ UTC happens in one place
///    (§10.1) and no datasource or cubit ever thinks about it.
/// 2. **Ambient school context**, for §9.7's required `schoolCode`.
///
/// Everything else is delegation. That is deliberate: with the datasource
/// returning raw JSON and the mappers pure, this class stays thin enough that
/// swapping the mock for HTTP cannot change behaviour.
class RegularizationRepositoryImpl implements RegularizationRepository {
  RegularizationRepositoryImpl(this._source, this._context);

  final RegRemoteDataSource _source;
  final RegContext _context;

  @override
  Future<MissedSignout?> getOpenSession(String staffCode) async {
    final zone = await _context.timeZone();
    final body = await _source.getOpenSessions(staffCode: staffCode);
    final items = RegMappers.listOf(body);
    if (items.isEmpty) return null;

    // §4 + §5.1 guarantee at most one unresolved day per staff. If a server
    // ever returns several, take the earliest — that is the one blocking, and
    // clearing it is what unblocks the next.
    final mapped = items
        .map((m) => RegMappers.toMissedSignout(m, zone: zone))
        .toList()
      ..sort((a, b) => a.attendanceDate.compareTo(b.attendanceDate));
    return mapped.first;
  }

  @override
  Future<RegBatchGate> getOpenSessionsBatch(List<String> staffCodes) async {
    if (staffCodes.isEmpty) return const RegBatchGate.empty();
    final zone = await _context.timeZone();
    final body = await _source.getOpenSessionsBatch(
      body: RegMappers.batchGateBody(staffCodes),
    );
    return RegMappers.toBatchGate(body, zone: zone);
  }

  @override
  Future<RegularizationRequest> raise(RegRaiseInput input) async {
    final zone = await _context.timeZone();
    final body = await _source.raise(
      body: RegMappers.raiseBody(input, zone: zone),
    );
    return RegMappers.toSingleRequest(body, zone: zone);
  }

  @override
  Future<RegBatchResult> raiseBatch(
    List<RegRaiseInput> items, {
    required String sharedReason,
  }) async {
    if (items.isEmpty) return const RegBatchResult.empty();
    final zone = await _context.timeZone();
    final body = await _source.raiseBatch(
      body: RegMappers.raiseBatchBody(
        items,
        sharedReason: sharedReason,
        zone: zone,
      ),
    );
    return RegMappers.toBatchResult(body);
  }

  @override
  Future<RegularizationRequest> edit(RegEditInput input) async {
    final zone = await _context.timeZone();
    try {
      final body = await _source.edit(
        code: input.code,
        body: RegMappers.editBody(input, zone: zone),
      );
      return RegMappers.toSingleRequest(body, zone: zone);
    } catch (error) {
      // §9.4 / §10.3 — an edit that races an approval loses. Translate the
      // bare 409 into something the UI can state plainly, because a silent
      // no-op would leave the user believing their correction applied.
      if (RegHttpErrors.isAlreadyApproved(error)) {
        throw RegAlreadyApprovedException(input.code);
      }
      rethrow;
    }
  }

  @override
  Future<RegPage<RegularizationRequest>> getMyRequests({
    required String staffCode,
    RegStatus? status,
    int page = 0,
    int size = 20,
    RegSortOrder sort = RegSortOrder.newestFirst,
  }) async {
    final zone = await _context.timeZone();
    final body = await _source.list(
      query: <String, dynamic>{
        'staffCode': staffCode,
        if (status != null) 'status': status.wireValue,
        'page': page,
        'size': size,
        'sort': sort.wireValue,
      },
    );
    return RegMappers.toPage(body, zone: zone, page: page, size: size);
  }

  @override
  Future<RegPage<RegularizationRequest>> getSchoolRequests({
    required String schoolCode,
    RegStatus? status,
    int page = 0,
    int size = 10,
    RegSortOrder sort = RegSortOrder.oldestFirst,
  }) async {
    final zone = await _context.timeZone();
    final body = await _source.list(
      query: <String, dynamic>{
        'schoolCode': schoolCode,
        // Omitted entirely when null — that is what returns the full history
        // for the admin's Approved / All tabs.
        if (status != null) 'status': status.wireValue,
        'page': page,
        'size': size,
        'sort': sort.wireValue,
      },
    );
    return RegMappers.toPage(body, zone: zone, page: page, size: size);
  }

  @override
  Future<RegularizationRequest> approve(
    String code, {
    DateTime? signOutLocal,
    String note = '',
  }) async {
    final zone = await _context.timeZone();
    final body = await _source.approve(
      code: code,
      body: RegMappers.approveBody(
        signOutLocal: signOutLocal,
        note: note,
        zone: zone,
      ),
    );
    return RegMappers.toSingleRequest(body, zone: zone);
  }

  @override
  Future<RegBatchResult> approveSelected(List<String> codes) async {
    if (codes.isEmpty) return const RegBatchResult.empty();
    final schoolCode = await _context.schoolCode();
    final body = await _source.approveSelected(
      body: RegMappers.approveSelectedBody(
        schoolCode: schoolCode,
        codes: codes,
      ),
    );
    return RegMappers.toBatchResult(body);
  }
}
