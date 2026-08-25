import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

/// Resolved school header values (name + optional tagline + address).
class _SchoolHeaderData {
  const _SchoolHeaderData({
    required this.name,
    this.tagline = '',
    this.address = '',
  });
  final String name;
  final String tagline;
  final String address;
}

/// Shared school header for billing receipt/invoice screens: shows the real
/// school logo-initials avatar, name, tagline, and address.
///
/// The name is read from local storage (always available); the tagline +
/// address are fetched once from `GET /api/v1/schools/{schoolCode}` and cached.
class BillingSchoolHeader extends StatefulWidget {
  const BillingSchoolHeader({super.key, this.avatarSize = 56});

  final double avatarSize;

  @override
  State<BillingSchoolHeader> createState() => _BillingSchoolHeaderState();
}

class _BillingSchoolHeaderState extends State<BillingSchoolHeader> {
  // Cached per school code so re-opening these screens doesn't refetch.
  static final Map<String, _SchoolHeaderData> _cache = {};

  _SchoolHeaderData _data = const _SchoolHeaderData(name: 'School');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = serviceLocator<StorageService>();
    final name = (await storage.getString(StorageKeys.selectedSchoolName) ?? '')
        .trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();

    if (mounted && name.isNotEmpty) {
      setState(() => _data = _SchoolHeaderData(name: name));
    }

    if (schoolCode.isEmpty) return;

    final cached = _cache[schoolCode];
    if (cached != null) {
      if (mounted) setState(() => _data = cached);
      return;
    }

    final fetched = await _fetchSchoolDetails(schoolCode, fallbackName: name);
    if (fetched == null) return;
    _cache[schoolCode] = fetched;
    if (mounted) setState(() => _data = fetched);
  }

  Future<_SchoolHeaderData?> _fetchSchoolDetails(
    String schoolCode, {
    required String fallbackName,
  }) async {
    try {
      final client = serviceLocator<ApiClient>().client;
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

      return _SchoolHeaderData(
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

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentImageWidget(
          fileUuid: '',
          name: _data.name,
          size: widget.avatarSize,
          fontSize: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _data.name,
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
              if (_data.tagline.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _data.tagline,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
              if (_data.address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _data.address,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
