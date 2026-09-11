import 'package:equatable/equatable.dart';

/// Typed carrier for the Forte tokenization webview init payload, built by
/// `AutoPayMethodsCubit.buildWebviewPayload` and consumed by
/// `AutoPayTokenWebView`.
///
/// The webview serializes this at the JS boundary via [toJsonMap] +
/// `jsonEncode`; this model itself is an in-app carrier (no JSON factories).
/// [toJsonMap] reproduces the exact map the cubit used to return, including the
/// conditional keys (`defaultMethod` only when set, `allowedMethods` only when
/// non-empty).
class AutoPayWebviewPayload extends Equatable {
  const AutoPayWebviewPayload({
    required this.env,
    required this.apiLoginId,
    required this.title,
    this.defaultMethod,
    this.allowedMethods = const <String>[],
  });

  final String env;
  final String apiLoginId;
  final String title;
  final String? defaultMethod;
  final List<String> allowedMethods;

  /// The map injected into the webview HTML. Mirrors the previous inline map
  /// shape 1:1 so the JS side sees identical JSON.
  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'env': env,
        'apiLoginId': apiLoginId,
        'title': title,
        if (defaultMethod != null) 'defaultMethod': defaultMethod,
        if (allowedMethods.isNotEmpty) 'allowedMethods': allowedMethods,
      };

  @override
  List<Object?> get props =>
      [env, apiLoginId, title, defaultMethod, allowedMethods];
}
