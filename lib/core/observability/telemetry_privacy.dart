import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/observability/telemetry_redactor.dart';

/// The privacy guardrails every Sentry payload passes through.
///
/// Three things leak record codes and names if left at the SDK defaults:
/// route arguments (go_router copies every query parameter into them), URL
/// query strings, and exception messages that embed a file path or a
/// presigned URL. [configure] turns off the automatic collectors that gather
/// such data and installs the scrubbing hooks below on everything that is
/// still sent. The hooks mutate in place where the SDK types allow it; they
/// never drop a payload.
abstract final class TelemetryPrivacy {
  TelemetryPrivacy._();

  /// Keys removed from breadcrumb data, span and transaction data, and log
  /// attributes.
  ///
  /// `*_arguments` are the navigation observer's copies of route arguments.
  /// `http.query` and `http.fragment` are the split-off parts of a request
  /// URL. `user.name` and `user.email` are stamped onto logs from the scope
  /// user even with `sendDefaultPii` off; the app sets an id only, this keeps
  /// it that way.
  static const Set<String> droppedKeys = {
    'from_arguments',
    'to_arguments',
    'route_settings_arguments',
    'http.query',
    'http.fragment',
    'user.name',
    'user.email',
  };

  static void configure(SentryFlutterOptions options) {
    options
      ..sendDefaultPii = false
      // 149 release-build debugPrints exist, some with coordinates and tokens.
      ..enablePrintBreadcrumbs = false
      ..attachScreenshot = false
      // Experimental in 9.x; set explicitly so a default change upstream
      // cannot switch it on.
      // ignore: experimental_member_use
      ..attachViewHierarchy = false
      ..beforeSend = beforeSend
      ..beforeSendTransaction = beforeSendTransaction
      ..beforeBreadcrumb = beforeBreadcrumb
      ..beforeSendLog = beforeSendLog;
    // The gateway enforces a strict request-header matrix, so no outgoing
    // request may carry Sentry's trace headers. The list is final on the
    // options object, hence cleared rather than reassigned.
    options.tracePropagationTargets.clear();
  }

  static SentryEvent? beforeSend(SentryEvent event, Hint hint) {
    _scrubEvent(event);
    return event;
  }

  static SentryTransaction? beforeSendTransaction(
    SentryTransaction transaction,
    Hint hint,
  ) {
    _scrubEvent(transaction);
    transaction.contexts.trace?.data?.removeWhere(_isDroppedKey);
    for (final span in transaction.spans) {
      // `SentrySpan.removeData` is a no-op once the span has finished, and
      // every span has finished by the time this hook runs.
      span.data.removeWhere(_isDroppedKey);
    }
    return transaction;
  }

  static Breadcrumb? beforeBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
    if (breadcrumb == null) return null;
    return _scrubBreadcrumb(breadcrumb);
  }

  static SentryLog? beforeSendLog(SentryLog log) {
    log.body = TelemetryRedactor.stripQueryStrings(log.body);
    log.attributes.removeWhere(_isDroppedKey);
    log.attributes.updateAll((_, attribute) {
      final value = attribute.value;
      if (value is! String) return attribute;
      final stripped = TelemetryRedactor.stripQueryStrings(value);
      return stripped == value ? attribute : SentryAttribute.string(stripped);
    });
    return log;
  }

  static void _scrubEvent(SentryEvent event) {
    for (final exception in event.exceptions ?? const <SentryException>[]) {
      final value = exception.value;
      if (value != null) {
        exception.value = TelemetryRedactor.redactPathsAndUrls(value);
      }
    }
    final message = event.message;
    if (message != null) {
      message.formatted = TelemetryRedactor.redactPathsAndUrls(
        message.formatted,
      );
      final template = message.template;
      if (template != null) {
        message.template = TelemetryRedactor.redactPathsAndUrls(template);
      }
    }
    final request = event.request;
    if (request != null) {
      event.request = _scrubRequest(request);
    }
    event.breadcrumbs = event.breadcrumbs?.map(_scrubBreadcrumb).toList();
    // Still serialised alongside `contexts`, so it must be scrubbed too.
    // ignore: deprecated_member_use
    event.extra?.removeWhere(_isDroppedKey);
  }

  /// Keeps only the method and the query-less URL: cookies, headers, body and
  /// environment are never diagnostic enough to justify what they carry.
  static SentryRequest _scrubRequest(SentryRequest request) {
    final url = request.url;
    return SentryRequest(
      method: request.method,
      url: url == null ? null : TelemetryRedactor.stripQueryString(url),
      apiTarget: request.apiTarget,
    );
  }

  static Breadcrumb _scrubBreadcrumb(Breadcrumb breadcrumb) {
    final message = breadcrumb.message;
    if (message != null) {
      breadcrumb.message = TelemetryRedactor.stripQueryStrings(message);
    }
    final data = breadcrumb.data;
    if (data != null) {
      breadcrumb.data = _scrubData(data);
    }
    return breadcrumb;
  }

  static Map<String, dynamic> _scrubData(Map<String, dynamic> data) {
    return {
      for (final MapEntry(:key, :value) in data.entries)
        if (!_isDroppedKey(key, value))
          key: value is String
              ? TelemetryRedactor.stripQueryStrings(value)
              : value,
    };
  }

  static bool _isDroppedKey(String key, Object? _) => droppedKeys.contains(key);
}
