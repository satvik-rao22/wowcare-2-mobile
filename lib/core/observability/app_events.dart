import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/observability/telemetry.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Every operation the app logs an outcome for, named `module.action`. The
/// logged name appends the [EventOutcome]: `auth.login.failed`.
///
/// A closed vocabulary on purpose, in the style of `MediaUploadTrace`: a new
/// event is a new value here, never a string at the call site. See
/// `docs/event-logging.md`.
enum AppEvent {
  authLogin('auth.login'),
  authLogout('auth.logout'),
  authSchoolSwitch('auth.school_switch'),
  authSession('auth.session'),
  attendanceStudentSignIn('attendance.student_sign_in'),
  attendanceStudentSignOut('attendance.student_sign_out'),
  attendanceStudentTransfer('attendance.student_transfer'),
  attendanceStudentMarkAbsent('attendance.student_mark_absent'),
  attendanceStaffSignIn('attendance.staff_sign_in'),
  attendanceStaffSignOut('attendance.staff_sign_out'),
  attendanceStaffTransfer('attendance.staff_transfer'),
  attendanceStaffMarkAbsent('attendance.staff_mark_absent'),
  activityCreate('activity.create'),
  activityUpdate('activity.update'),
  activityApprove('activity.approve'),
  activityReject('activity.reject'),
  activityAcknowledge('activity.acknowledge'),

  /// The guardian's incident signature, which is how the app acknowledges.
  activityParentSignature('activity.parent_signature'),
  activityShare('activity.share'),

  /// One batch of media uploaded for one activity; count is the item count.
  activityUploadBatch('activity.upload_batch'),
  eventCreate('event.create'),

  /// Whole series, or this-and-future when split from an occurrence.
  eventUpdate('event.update'),

  /// Whole series, or cancelling from one occurrence onward.
  eventDelete('event.delete'),
  eventOccurrenceUpdate('event.occurrence_update'),

  /// Deleting a single occurrence, which the server records as a cancel.
  eventOccurrenceCancel('event.occurrence_cancel'),

  /// count is the number of assignees.
  taskCreate('task.create'),

  /// Series-wide edit; count is the new assignee roster when it changed.
  taskUpdate('task.update'),

  /// One assignment edited from the form, which can also change its status.
  taskAssignmentUpdate('task.assignment_update'),
  taskUnassign('task.unassign'),
  taskStatusChange('task.status_change');

  const AppEvent(this.key);

  final String key;
}

/// How an operation ended. `expired` exists for `auth.session` alone.
enum EventOutcome { succeeded, failed, expired }

/// Why an operation failed, in buckets coarse enough to carry no user data.
enum EventFailure {
  network,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  validation,

  /// The server answered with an error. Repository [Failure]s do not keep the
  /// status code; the matching write-request log has it.
  server,

  /// The app refused on purpose, e.g. a web-only role signing in on mobile.
  blocked,
  unknown;

  /// Buckets a thrown error or a repository [Failure].
  static EventFailure of(Object? error) {
    return switch (error) {
      DioException(type: DioExceptionType.cancel) => cancelled,
      DioException(
        type: DioExceptionType.connectionTimeout ||
            DioExceptionType.sendTimeout ||
            DioExceptionType.receiveTimeout,
      ) =>
        timeout,
      DioException(type: DioExceptionType.connectionError) => network,
      DioException(:final response?) => _ofStatus(response.statusCode),
      SocketException() || NetworkFailure() => network,
      TimeoutException() => timeout,
      AuthorizationFailure() => forbidden,
      ValidationFailure() => validation,
      ServerFailure() => server,
      _ => unknown,
    };
  }

  static EventFailure _ofStatus(int? status) {
    return switch (status) {
      401 => unauthorized,
      403 => forbidden,
      404 => notFound,
      400 || 409 || 422 => validation,
      _ => server,
    };
  }
}

/// Logs one structured line per operation outcome, to Sentry Logs and as a
/// breadcrumb on any later error report.
///
/// The personal-data rule is enforced by the signature: an event carries its
/// name, an outcome, a failure bucket, a count and a duration, and nothing
/// else. Never add a free-text or identifier parameter here.
abstract final class AppEvents {
  AppEvents._();

  static void record(
    AppEvent event,
    EventOutcome outcome, {
    EventFailure? failure,
    int? count,
    int? durationMs,
  }) {
    final name = '${event.key}.${outcome.name}';
    AppLogger.trail(name);
    Telemetry.log(
      name,
      level: outcome == EventOutcome.succeeded
          ? TelemetryLogLevel.info
          : TelemetryLogLevel.warn,
      attributes: {
        'event': event.key,
        'outcome': outcome.name,
        if (failure != null) 'failure': failure.name,
        if (count != null) 'count': count,
        if (durationMs != null) 'duration_ms': durationMs,
      },
    );
  }

  static void succeeded(AppEvent event, {int? count, int? durationMs}) {
    record(event, EventOutcome.succeeded, count: count, durationMs: durationMs);
  }

  /// [error] is a thrown error or [Failure], bucketed by [EventFailure.of]
  /// and never sent, or an [EventFailure] when the caller knows the bucket.
  static void failed(
    AppEvent event,
    Object? error, {
    int? count,
    int? durationMs,
  }) {
    record(
      event,
      EventOutcome.failed,
      failure: error is EventFailure ? error : EventFailure.of(error),
      count: count,
      durationMs: durationMs,
    );
  }

  /// Runs [operation] and logs its outcome with its duration. A throw is
  /// logged as failed and rethrown untouched.
  ///
  /// For operations that report failure in their result instead of throwing
  /// (an `Either`, a `success` flag), [failureOf] returns the bucket for a
  /// failed result and null for a good one.
  static Future<T> track<T>(
    AppEvent event,
    Future<T> Function() operation, {
    int? count,
    EventFailure? Function(T result)? failureOf,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      final failure = failureOf?.call(result);
      final durationMs = stopwatch.elapsedMilliseconds;
      if (failure == null) {
        succeeded(event, count: count, durationMs: durationMs);
      } else {
        failed(event, failure, count: count, durationMs: durationMs);
      }
      return result;
    } catch (error) {
      failed(
        event,
        error,
        count: count,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    }
  }
}
