import 'package:equatable/equatable.dart';

/// Typed model for an OUTBOUND activity parameter-value row, used when building
/// the CREATE, SHARED-create and UPDATE request payloads.
///
/// Replaces the raw `List<Map<String, dynamic>>` the create/edit form screens
/// and cubits used to build by hand. Every entry always carries a
/// [parameterCode]; each also carries EITHER a [value] (any type — String,
/// bool, num, and sometimes the empty string) OR a [selectedOptionCode]
/// (String). A rare entry additionally carries other keys (e.g. `mediaType`),
/// which are preserved verbatim in [extra].
///
/// [toPayload] reproduces each original Map key-for-key so the JSON on the wire
/// stays byte-for-byte identical:
///
///  * [value] is emitted only when non-null — so an entry built with
///    `value: ''` keeps a present-but-empty `value` key, while an entry built
///    with `value: null` (the default) omits the key entirely, matching the
///    old Map literals that never wrote a `value` key.
///  * [selectedOptionCode] is emitted only when non-null AND non-empty,
///    matching the prior branch that wrote it only on the option path.
///  * [extra] keys are spread in verbatim, so rare additional keys survive.
///
/// Scope note: this is the OUTBOUND request payload only. Code that READS
/// parameter values from a server RESPONSE / [ActivityDetail] stays
/// `Map<String, dynamic>`; where such a read row is re-sent, wrap it in an
/// [ActivityParameterValue] (using [extra] for any non-value/selectedOptionCode
/// keys) at the point it is added to the outbound list.
class ActivityParameterValue extends Equatable {
  const ActivityParameterValue({
    required this.parameterCode,
    this.value,
    this.selectedOptionCode,
    this.extra = const {},
  });

  final String parameterCode;

  /// Present (including the empty string) vs absent: a non-null value keeps the
  /// `value` key, `null` omits it.
  final Object? value;

  /// Present vs absent: emitted only when non-null and non-empty.
  final String? selectedOptionCode;

  /// Rare extra keys (e.g. `mediaType`) preserved verbatim.
  final Map<String, dynamic> extra;

  /// Reproduces the exact Map the old code built. See the class doc for the
  /// key-presence rules that keep the wire JSON byte-for-byte identical.
  Map<String, dynamic> toPayload() => <String, dynamic>{
        'parameterCode': parameterCode,
        if (value != null) 'value': value,
        if ((selectedOptionCode ?? '').isNotEmpty)
          'selectedOptionCode': selectedOptionCode,
        ...extra,
      };

  @override
  List<Object?> get props => [parameterCode, value, selectedOptionCode, extra];
}
