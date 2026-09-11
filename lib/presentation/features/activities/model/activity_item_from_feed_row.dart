import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/data/features/activity/mappers/activity_patch_attachments.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import 'package:wowcare/domain/features/activity/services/activity_staff_display.dart';
import 'package:wowcare/presentation/features/activities/model/activity_item.dart';

/// Maps API feed rows onto the [ActivityItem] view model.
///
/// Extracted from `view/activity_daily_tab.dart`, where ~570 lines of pure
/// mapping sat at the bottom of a 5,600-line widget file — and where
/// `activity_feed_cubit` had to import a *view* to reach it, inverting the
/// MVVM dependency direction. Nothing here touches Flutter.
final Map<String, Map<String, String>> _activityFeedOptionLabelCache = {};

Future<void> ensureActivityFeedOptionLabelsForType(
  String activityTypeCode,
) async {
  final c = activityTypeCode.trim();
  if (c.isEmpty) return;
  if (_activityFeedOptionLabelCache.containsKey(c)) return;
  try {
    final uc = serviceLocator<GetActivityTypeDetailsUseCase>();
    final d = await uc(code: c);
    final map = <String, String>{};
    for (final param in d.parameters) {
      for (final o in param.options) {
        final lbl = (o.optionLabel ?? '').trim();
        if (lbl.isEmpty) continue;
        final oc = (o.optionCode ?? '').trim();
        final rawCode = o.code.trim();
        if (oc.isNotEmpty) map[oc] = lbl;
        if (rawCode.isNotEmpty && rawCode != oc) map[rawCode] = lbl;
      }
    }
    _activityFeedOptionLabelCache[c] = map;
  } catch (_) {
    _activityFeedOptionLabelCache[c] = {};
  }
}

Future<void> primeActivityFeedOptionLabelsFromRows(
  Iterable<ActivityFeedRow> rows,
) async {
  final codes = <String>{};
  for (final r in rows) {
    if (mapApiActivityTypeNameToUiLabel(r.activityTypeName) != 'Learning')
      continue;
    final code = r.activityTypeCode.trim();
    if (code.isNotEmpty) codes.add(code);
  }
  await Future.wait(codes.map(ensureActivityFeedOptionLabelsForType));
}

Map<String, String>? activityFeedOptionLabelsForType(String activityTypeCode) {
  final map = _activityFeedOptionLabelCache[activityTypeCode.trim()];
  if (map == null || map.isEmpty) return null;
  return map;
}

String? _resolveLearningFeedParamDisplay(
  Map<String, dynamic> p,
  Map<String, String> codeToLabel,
) {
  for (final key in ['selectedOptionLabel', 'optionLabel']) {
    final v = (p[key] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }

  final dt = (p['dataType'] ?? '').toString().toUpperCase();
  if (dt == 'DATE') {
    final d = (p['valueDate'] ?? '').toString().trim();
    if (d.isNotEmpty) return d;
  }
  if (dt == 'TIME') {
    final t = (p['valueTime'] ?? '').toString().trim();
    if (t.isNotEmpty) return t;
  }

  final sel = (p['selectedOptionCode'] ?? '').toString().trim();
  if (sel.isNotEmpty) {
    final hit = codeToLabel[sel];
    if (hit != null && hit.isNotEmpty) return hit;
  }

  for (final key in ['valueText', 'valueNumber']) {
    final raw = (p[key] ?? '').toString().trim();
    if (raw.isEmpty) continue;
    final hit = codeToLabel[raw];
    if (hit != null && hit.isNotEmpty) return hit;
    return raw;
  }
  return null;
}

/// Maps backend [ActivityFeedRow.activityTypeName] to UI keys used in [activityRoutes].
String mapApiActivityTypeNameToUiLabel(String apiName) {
  final s = apiName.toLowerCase().trim();
  if (s.isEmpty) return 'Notes';
  if (s.contains('nap')) {
    if (s.contains('start')) return 'Nap Start';
    if (s.contains('end') || s.contains('stop') || s.contains('wake')) {
      return 'Nap End';
    }
    return 'Nap Start';
  }
  if (s.contains('bathroom') || s.contains('potty') || s.contains('diaper')) {
    return 'Bathroom';
  }
  if (s.contains('bottle')) return 'Bottle';
  if (s.contains('meal') ||
      s.contains('lunch') ||
      s.contains('breakfast') ||
      s.contains('snack')) {
    return 'Meal';
  }
  if (s.contains('incident')) return 'Incident';
  if (s.contains('medication') || s.contains('medicine')) {
    return 'Medication';
  }
  if (s.contains('outdoor') || s.contains('outside')) return 'Outdoor';
  if (s.contains('learning')) return 'Learning';
  if (s.contains('photo') && !s.contains('video')) return 'Photo';
  if (s.contains('video')) return 'Video';
  if (s.contains('note')) return 'Notes';
  if (s.contains('sign') && s.contains('in')) return 'Sign-in';
  if (s.contains('sign') && s.contains('out')) return 'Sign-out';
  if (s.contains('absent')) return 'Marked Absent';
  return apiName.trim();
}

ActivityItem activityItemFromFeedRow(
  ActivityFeedRow row, {
  String? viewerDisplayName,
  String? schoolIana,
  Map<String, String>? staffDisplayNameByCode,
  Map<String, String>? activityTypeOptionCodeToLabel,
}) {
  bool? _boolFromAny(dynamic raw) {
    if (raw is bool) return raw;
    final v = (raw ?? '').toString().trim().toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
    return null;
  }

  bool? _pickNapFlagFromParameters(bool wantEnd) {
    for (final p in row.parameterValues) {
      final name = (p['parameterName'] ?? '').toString().toLowerCase().trim();
      if (!name.contains('nap')) continue;
      final hasTarget = wantEnd
          ? (name.contains('end') ||
                name.contains('wake') ||
                name.contains('stop'))
          : (name.contains('start') || name.contains('begin'));
      if (!hasTarget) continue;
      final fromBool = _boolFromAny(p['valueBool']);
      if (fromBool != null) return fromBool;
      final fromText = _boolFromAny(p['valueText']);
      if (fromText != null) return fromText;
      final fromOption = _boolFromAny(p['selectedOptionLabel']);
      if (fromOption != null) return fromOption;
    }
    return null;
  }

  DateTime dt;
  try {
    final parsed = DateTime.parse(row.activityDateIso);
    final iana = (schoolIana ?? '').trim();
    dt = iana.isEmpty
        ? parsed.toLocal()
        : SchoolZoneDateTime.dateTimeFromInstantInSchool(parsed, iana);
  } catch (_) {
    dt = AppTime.now();
  }
  final time = DateFormat.jm().format(dt);
  final date = DateFormat('MMMM d, yyyy').format(dt);
  var name = mapApiActivityTypeNameToUiLabel(row.activityTypeName);
  final rowNapEnd = row.napEnd ?? _pickNapFlagFromParameters(true);
  final rowNapStart = row.napStart ?? _pickNapFlagFromParameters(false);
  if (name == 'Nap Start' || name == 'Nap End') {
    if (rowNapEnd == true) {
      name = 'Nap End';
    } else if (rowNapStart == true) {
      name = 'Nap Start';
    }
  }

  String? photoUrl;
  String? videoUrl;
  for (final a in row.attachments) {
    final mt = (a['mediaType'] ?? '').toString().toLowerCase();
    // Fall back to processed variant URLs so images already render even while
    // the backend still reports status == PROCESSING (deliveryUrl null).
    final u = attachmentUsableDeliveryUrl(a);
    if (u.isEmpty) continue;
    if (mt.contains('video') ||
        u.toLowerCase().endsWith('.mp4') ||
        u.toLowerCase().endsWith('.mov')) {
      videoUrl ??= u;
    } else {
      photoUrl ??= u;
    }
  }

  String? pickParam(bool Function(String n) match) {
    for (final p in row.parameterValues) {
      final n = (p['parameterName'] ?? '').toString().toLowerCase();
      if (!match(n)) continue;
      if (name == 'Learning') {
        final m = activityTypeOptionCodeToLabel;
        if (m != null && m.isNotEmpty) {
          final resolved = _resolveLearningFeedParamDisplay(p, m);
          if (resolved != null && resolved.isNotEmpty) return resolved;
        }
      }
      // Prefer human-readable labels (dropdowns) before option codes in valueText.
      for (final key in <String>[
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
        'valueNumber',
        'valueTime',
        'valueDatetime',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  String? pickStaffPresentFromParameters() {
    for (final p in row.parameterValues) {
      final n = (p['parameterName'] ?? '').toString().toLowerCase();
      if (n != 'staff present') continue;
      final dt = (p['dataType'] ?? '').toString().toUpperCase();
      if (dt == 'DATE' || dt == 'TIME') continue;
      for (final key in <String>[
        'selectedOptionCode',
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
        'valueNumber',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  String? paramDisplay(Map<String, dynamic> p) {
    for (final key in <String>[
      'selectedOptionLabel',
      'valueText',
      'valueNumber',
      'valueTime',
      'valueDatetime',
    ]) {
      final v = (p[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  /// Prefer [valueNumber] when present so fractional oz (e.g. 0.5) is not
  /// replaced by a stale [valueText] such as "0".
  String? bottleVolumeSingleParam(Map<String, dynamic> p) {
    final vnRaw = p['valueNumber'];
    final vnStr = vnRaw != null ? vnRaw.toString().trim() : '';
    final vn = vnStr.isNotEmpty
        ? double.tryParse(vnStr.replaceAll(',', ''))
        : null;

    String? textVal;
    for (final key in <String>[
      'selectedOptionLabel',
      'optionLabel',
      'valueText',
    ]) {
      final v = (p[key] ?? '').toString().trim();
      if (v.isNotEmpty) {
        textVal = v;
        break;
      }
    }

    double? numFromText;
    if (textVal != null) {
      final m = RegExp(
        r'(\d+(?:\.\d+)?)',
      ).firstMatch(textVal.replaceAll(',', ''));
      if (m != null) {
        numFromText = double.tryParse(m.group(1)!);
      }
    }

    if (vn != null && numFromText != null && numFromText > 0) {
      if ((vn - 2 * numFromText).abs() < 0.001) {
        return numFromText == numFromText.roundToDouble()
            ? numFromText.round().toString()
            : numFromText.toString();
      }
    }

    if (vnRaw != null && vnStr.isNotEmpty) {
      return vnStr;
    }
    for (final key in <String>[
      'selectedOptionLabel',
      'optionLabel',
      'valueText',
      'valueTime',
      'valueDatetime',
    ]) {
      final v = (p[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  String? pickParamBottleVolume() {
    for (final p in row.parameterValues) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      final isVol =
          pn.contains('amount') ||
          pn.contains('ounce') ||
          pn.contains('volume') ||
          pn.contains(' ml') ||
          RegExp(r'\boz\b').hasMatch(pn);
      if (!isVol || pn.contains('consumption')) continue;
      final vol = bottleVolumeSingleParam(p);
      if (vol != null && vol.isNotEmpty) return vol;
    }
    return null;
  }

  String? bottleVolumeFromParams;
  String? bottleStatusFromParams;
  if (name == 'Bottle') {
    for (final p in row.parameterValues) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      final dt = (p['dataType'] ?? '').toString().toUpperCase();
      if (pn.contains('staff')) continue;
      if (dt == 'DATE' || dt == 'TIME') continue;
      if (pn == 'description' || (pn.contains('description') && dt == 'TEXT'))
        continue;
      final isConsumptionDropdown =
          dt == 'DROPDOWN' &&
          (pn.contains('consum') ||
              pn.contains('intake') ||
              pn.contains('status') ||
              pn.contains('left'));
      final isConsumptionText =
          !pn.contains('amount') &&
          !pn.contains('ounce') &&
          !pn.contains('volume') &&
          (pn.contains('consum') || pn.contains('intake'));
      if (isConsumptionDropdown || isConsumptionText) {
        final val = paramDisplay(p);
        if (val == null || val.isEmpty) continue;
        bottleStatusFromParams ??= val;
        continue;
      }
      final isVolume =
          pn.contains('amount') ||
          pn.contains('ounce') ||
          pn.contains('volume') ||
          pn.contains(' ml') ||
          RegExp(r'\boz\b').hasMatch(pn);
      if (isVolume) {
        final vol = bottleVolumeSingleParam(p);
        if (vol != null && vol.isNotEmpty) {
          bottleVolumeFromParams ??= vol;
        }
      }
    }
  }

  final amountConsumed = name == 'Bottle'
      ? (bottleVolumeFromParams ??
            pickParamBottleVolume() ??
            pickParam(
              (n) =>
                  (n.contains('amount') ||
                      n.contains('ounce') ||
                      n.contains('oz')) &&
                  !n.contains('consumption'),
            ))
      : pickParam(
          (n) =>
              n.contains('amount') ||
              n.contains('ounce') ||
              n.contains('oz') ||
              n.contains('consumed'),
        );
  final mealType =
      pickParam((n) => n.contains('meal') && n.contains('type')) ??
      pickParam((n) => n.contains('meal') && !n.contains('quantity'));
  final mealQuantity = name == 'Meal'
      ? pickParam(
          (n) =>
              (n.contains('quant') || n.contains('portion')) &&
              !n.contains('meal type'),
        )
      : pickParam((n) => n.contains('quantity') || n.contains('portion'));
  final napStartTime =
      pickParam((n) => n.contains('nap') && n.contains('start')) ??
      pickParam((n) => n.contains('start') && n.contains('nap'));
  final napEndTime =
      pickParam(
        (n) => n.contains('nap') && (n.contains('end') || n.contains('stop')),
      ) ??
      pickParam(
        (n) =>
            n.contains('end') &&
            n.contains('nap') &&
            (n.contains('time') || n.contains('stop')),
      );

  /// Single "Time" param (e.g. PM_027) when nap start/end params are absent.
  final napTimeParam = pickParam((n) => n.trim().toLowerCase() == 'time');
  final bathroomType =
      pickParam((n) => n.contains('bathroom') && n.contains('type')) ??
      pickParam((n) => n.contains('potty') || n.contains('diaper'));
  final bathroomSubType =
      pickParam((n) => n.contains('sub') && n.contains('type')) ??
      pickParam((n) => n.contains('subtype'));

  String? pickBathroomDiaperSizeFromParams() {
    for (final p in row.parameterValues) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      if (!pn.contains('size')) continue;
      if (pn.contains('subtype')) continue;
      if (pn.contains('sub type')) continue;
      for (final key in <String>[
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
        'valueNumber',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  final bathroomDiaperSizeLabel = name == 'Bathroom'
      ? pickBathroomDiaperSizeFromParams()
      : null;

  // No synthesized fallback for Nap Start/Nap End: web renders an empty
  // description as empty, so substituting "Nap Started"/"Nap Ended" here made
  // the same activity read differently on the two platforms.
  final effectiveDescription = row.description.trim();
  final studentNamesFromApi = row.students
      .map((s) => (s['name'] ?? '').trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final studentName = row.studentDisplayName.isEmpty
      ? 'Student'
      : row.studentDisplayName;
  final studentListForItem = studentNamesFromApi.isNotEmpty
      ? studentNamesFromApi
      : [studentName];
  final staffFromParams = pickStaffPresentFromParameters();
  final mappedStaffName = (() {
    final raw = (staffFromParams ?? '').trim();
    if (raw.isEmpty) return null;
    final resolved = staffDisplayNameByCode?[raw]?.trim() ?? '';
    if (resolved.isNotEmpty) return resolved;
    return raw;
  })();
  final by = resolveActivityCreatedByForUi(
    rawCreatedBy: '',
    staffLabelFromParameters: mappedStaffName,
    viewerDisplayNameFallback: null,
  );

  /// Learning: API stores these in [parameterValues] (e.g. PM_054 Activity Name, PM_055 Categories).
  final String? learningActivityName = name == 'Learning'
      ? (pickParam(
              (n) =>
                  n.contains('activity') &&
                  (n.contains('name') || n.contains('type')),
            ) ??
            pickParam((n) => n.contains('learning') && !n.contains('categor')))
      : null;
  final String? learningCategory = name == 'Learning'
      ? pickParam((n) => n.contains('categor'))
      : null;

  final sc = (row.studentCode ?? '').trim();
  final ac = (row.activityCode ?? '').trim();

  /// Incident's "Additional Notes" (CUSTOM parameter, distinct from "What
  /// happened?" which the API already surfaces via [row.description]) has
  /// no flat field on [ActivityFeedRow] — it must be read out of
  /// [row.parameterValues] like every other custom parameter (bathroomType,
  /// mealType, …) below.
  final additionalNotesFromParams = name == 'Incident'
      ? pickParam((n) => n.contains('additional') && n.contains('note'))
      : null;

  return ActivityItem(
    time: time,
    date: date,
    name: name,
    description: effectiveDescription.isEmpty ? null : effectiveDescription,
    photoUrl: photoUrl,
    videoUrl: videoUrl,
    studentList: studentListForItem,
    createdBy: by,
    activityType: learningActivityName,
    categoryType: learningCategory != null && learningCategory.isNotEmpty
        ? [learningCategory]
        : null,
    mealType: name == 'Meal' ? mealType : null,
    mealQuantity: name == 'Meal' ? mealQuantity : null,
    amountConsumed: name == 'Bottle' ? amountConsumed : null,
    bottleConsumptionStatus: name == 'Bottle' ? bottleStatusFromParams : null,
    napStartTime: (name == 'Nap Start' || name == 'Nap End')
        ? (napStartTime ?? napTimeParam)
        : null,
    napEndTime: name == 'Nap End' ? (napEndTime ?? napTimeParam) : null,
    whatHappened:
        (name == 'Incident' || name == 'Notes') &&
            effectiveDescription.isNotEmpty
        ? effectiveDescription
        : null,
    additionalNotes: additionalNotesFromParams,
    staffPresent: by,
    staffPresentCode: (staffFromParams ?? '').trim().isEmpty
        ? null
        : staffFromParams!.trim(),
    bathroomType: name == 'Bathroom' ? bathroomType : null,
    bathroomSubType: name == 'Bathroom' ? bathroomSubType : null,
    bathroomDiaperSize: name == 'Bathroom' ? bathroomDiaperSizeLabel : null,
    activityTypeCode: row.activityTypeCode.trim().isEmpty
        ? null
        : row.activityTypeCode.trim(),
    activityCode: ac.isEmpty ? null : ac,
    studentCode: sc.isEmpty ? null : sc,
    classroomCode: (row.classroomCode ?? '').trim().isEmpty
        ? null
        : row.classroomCode!.trim(),
    activityDateIso: row.activityDateIso.trim().isEmpty
        ? null
        : row.activityDateIso.trim(),
    snapshotAttachments: row.attachments.isEmpty
        ? null
        : row.attachments.map((e) => Map<String, dynamic>.from(e)).toList(),
    studentActivityRefs: row.students.isNotEmpty
        ? row.students
              .map(
                (s) => <String, String>{
                  'name': (s['name'] ?? '').trim(),
                  if ((s['studentCode'] ?? '').trim().isNotEmpty)
                    'studentCode': s['studentCode']!.trim(),
                  if (ac.isNotEmpty) 'activityCode': ac,
                },
              )
              .where((m) => (m['name'] ?? '').isNotEmpty)
              .toList()
        : [
            {
              'name': studentName,
              if (sc.isNotEmpty) 'studentCode': sc,
              if (ac.isNotEmpty) 'activityCode': ac,
            },
          ],
    approvalStatus: row.approvalStatus,
  );
}
