import '../../core/config/reg_config.dart';
import '../../core/errors/reg_exceptions.dart';
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

/// Resolves the school zone once per call and hands it to the mappers; the rest
/// is delegation.
class RegularizationRepositoryImpl implements RegularizationRepository {
  RegularizationRepositoryImpl(this._source, this._context);

  final RegRemoteDataSource _source;
  final RegContext _context;

  @override
  Future<RegBatchGate> checkGate({List<String>? staffCodes}) async {
    final zone = await _context.timeZone();
    final body = await _source.checkGate(RegMappers.gateBody(staffCodes));
    return RegMappers.toBatchGate(body, zone: zone);
  }

  @override
  Future<RegularizationRequest> raise(
    RegRaiseInput input, {
    String method = RegConfig.method,
  }) async {
    final zone = await _context.timeZone();
    final body = await _source.raise(
      RegMappers.raiseBody(input, zone: zone, method: method),
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
      RegMappers.raiseBatchBody(items, sharedReason: sharedReason, zone: zone),
    );
    return RegMappers.toBatchResult(body);
  }

  @override
  Future<RegPage<RegularizationRequest>> getRequests({
    String? staffCode,
    RegStatus? status,
    int page = 0,
    int size = 20,
    RegSortOrder sort = RegSortOrder.newestFirst,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final zone = await _context.timeZone();
    final body = await _source.list(<String, dynamic>{
      if (staffCode != null && staffCode.isNotEmpty) 'staffCode': staffCode,
      if (status != null) 'status': status.wireValue,
      'page': page,
      'size': size,
      'sort': sort.wireValue,
      if (fromDate != null) 'fromDate': _ymd(fromDate),
      if (toDate != null) 'toDate': _ymd(toDate),
    });
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
      code,
      RegMappers.approveBody(
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
    final body = await _source.approveSelected(
      RegMappers.approveSelectedBody(codes),
    );
    return RegMappers.toBatchResult(body);
  }

  @override
  Future<RegularizationRequest> edit(RegEditInput input) async {
    final zone = await _context.timeZone();
    try {
      final body = await _source.edit(
        input.code,
        RegMappers.editBody(input, zone: zone),
      );
      return RegMappers.toSingleRequest(body, zone: zone);
    } catch (error) {
      // A silent no-op would leave the user believing their change applied.
      if (RegHttpErrors.isAlreadyApproved(error)) {
        throw RegAlreadyApprovedException(input.code);
      }
      rethrow;
    }
  }

  /// `2026-09-30` — the calendar-date shape the list endpoints use.
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
