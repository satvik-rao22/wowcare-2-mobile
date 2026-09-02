import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/storage_keys.dart';

part 'billing_school_header_state.dart';

/// Resolves the billing school header (name + optional tagline + address).
///
/// The name is read from local storage (always available); the tagline +
/// address are fetched once from `GET /api/v1/schools/{schoolCode}` and cached.
class BillingSchoolHeaderCubit extends Cubit<BillingSchoolHeaderState> {
  BillingSchoolHeaderCubit({
    required StorageService storageService,
    required ApiClient apiClient,
  })  : _storageService = storageService,
        _apiClient = apiClient,
        super(const BillingSchoolHeaderState());

  final StorageService _storageService;
  final ApiClient _apiClient;

  // Cached per school code so re-opening these screens doesn't refetch.
  static final Map<String, BillingSchoolHeaderState> _cache = {};

  Future<void> load() async {
    final name =
        (await _storageService.getString(StorageKeys.selectedSchoolName) ?? '')
            .trim();
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

    if (name.isNotEmpty) {
      emit(state.copyWith(name: name));
    }

    if (schoolCode.isEmpty) return;

    final cached = _cache[schoolCode];
    if (cached != null) {
      emit(cached);
      return;
    }

    final fetched = await _fetchSchoolDetails(schoolCode, fallbackName: name);
    if (fetched == null) return;
    _cache[schoolCode] = fetched;
    emit(fetched);
  }

  Future<BillingSchoolHeaderState?> _fetchSchoolDetails(
    String schoolCode, {
    required String fallbackName,
  }) async {
    try {
      final client = _apiClient.client;
      final response = await client.get<dynamic>(
        ApiPaths.url(ApiPaths.schoolByCode(schoolCode)),
      );
      final body = response.data;
      if (body is! Map) return null;
      final data = (body['data'] is Map ? body['data'] : body) as Map;

      String pick(List<String> keys) {
        for (final k in keys) {
          final v = (data[k] ?? '').toString().trim();
          if (v.isNotEmpty) return v;
        }
        return '';
      }

      final name = pick(['name', 'schoolName']);
      final tagline = pick(['tagline', 'description', 'about', 'slogan']);

      // Address may be a nested object or flat fields on the school.
      Map addr = data['address'] is Map ? data['address'] as Map : data;
      String addrPick(List<String> keys) {
        for (final k in keys) {
          final v = (addr[k] ?? '').toString().trim();
          if (v.isNotEmpty) return v;
        }
        return '';
      }

      final addressParts = <String>[
        addrPick(['line1', 'addressLine1', 'line', 'street', 'addressLine']),
        addrPick(['line2', 'addressLine2']),
        addrPick(['city']),
        addrPick(['state', 'province']),
        addrPick(['country']),
        addrPick(['postalCode', 'zipCode', 'zipcode', 'zip']),
      ].where((p) => p.isNotEmpty).toList();

      return BillingSchoolHeaderState(
        name: name.isNotEmpty
            ? name
            : (fallbackName.isNotEmpty ? fallbackName : 'School'),
        tagline: tagline,
        address: addressParts.join(', '),
      );
    } catch (_) {
      return null;
    }
  }
}
