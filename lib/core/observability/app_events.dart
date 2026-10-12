import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dartz/dartz.dart' show Either;
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

  /// A password-reset email requested from the sign-in screen.
  authForgotPassword('auth.forgot_password'),
  attendanceStudentSignIn('attendance.student_sign_in'),
  attendanceStudentSignOut('attendance.student_sign_out'),
  attendanceStudentTransfer('attendance.student_transfer'),
  attendanceStudentMarkAbsent('attendance.student_mark_absent'),
  attendanceStaffSignIn('attendance.staff_sign_in'),
  attendanceStaffSignOut('attendance.staff_sign_out'),
  attendanceStaffTransfer('attendance.staff_transfer'),
  attendanceStaffMarkAbsent('attendance.staff_mark_absent'),

  /// Corrections from the attendance history, one record per event.
  attendanceStudentRecordUpdate('attendance.student_record_update'),
  attendanceStudentRecordDelete('attendance.student_record_delete'),
  attendanceStudentAbsenceDelete('attendance.student_absence_delete'),
  attendanceStaffRecordUpdate('attendance.staff_record_update'),
  attendanceStaffRecordDelete('attendance.staff_record_delete'),
  attendanceStaffAbsenceDelete('attendance.staff_absence_delete'),
  attendanceQrValidate('attendance.qr_validate'),

  /// The GPS fix and geofence check taken before a sign-in or sign-out.
  /// Failed means the submit fell back without a location.
  attendanceLocationCheck('attendance.location_check'),
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
  activityDelete('activity.delete'),

  /// Media found staged on the device from an earlier, interrupted upload;
  /// count is the number of items recovered.
  activityMediaRecover('activity.media_recover'),
  eventCreate('event.create'),

  /// Whole series, or this-and-future when split from an occurrence.
  eventUpdate('event.update'),

  /// Whole series, or cancelling from one occurrence onward.
  eventDelete('event.delete'),
  eventOccurrenceUpdate('event.occurrence_update'),

  /// Deleting a single occurrence, which the server records as a cancel.
  eventOccurrenceCancel('event.occurrence_cancel'),

  /// A guardian or staff RSVP to an event.
  eventRsvp('event.rsvp'),

  /// count is the number of files.
  eventAttachmentUpload('event.attachment_upload'),
  eventHolidayCreate('event.holiday_create'),
  eventHolidayUpdate('event.holiday_update'),
  eventHolidayDelete('event.holiday_delete'),
  eventHolidayStatusChange('event.holiday_status_change'),

  /// count is the number of assignees.
  taskCreate('task.create'),

  /// Series-wide edit; count is the new assignee roster when it changed.
  taskUpdate('task.update'),

  /// One assignment edited from the form, which can also change its status.
  taskAssignmentUpdate('task.assignment_update'),
  taskUnassign('task.unassign'),
  taskStatusChange('task.status_change'),
  taskDelete('task.delete'),
  taskAssignmentDelete('task.assignment_delete'),
  taskOccurrenceUpdate('task.occurrence_update'),
  taskOccurrenceCancel('task.occurrence_cancel'),

  /// count is the number of files.
  taskAttachmentUpload('task.attachment_upload'),
  taskAttachmentDetach('task.attachment_detach'),

  /// An admin recording a payment against an invoice.
  billingPayment('billing.payment'),

  /// Succeeded means the server accepted the charge, not that it settled.
  billingGuardianPay('billing.guardian_pay'),
  billingPaymentMethodAdd('billing.payment_method_add'),
  billingPaymentMethodRemove('billing.payment_method_remove'),
  billingAutopayEnable('billing.autopay_enable'),
  billingAutopayDisable('billing.autopay_disable'),
  billingInvoiceCreate('billing.invoice_create'),
  billingInvoiceIssue('billing.invoice_issue'),
  billingInvoiceCancel('billing.invoice_cancel'),
  billingRefund('billing.refund'),
  billingInvoiceUpdate('billing.invoice_update'),
  billingInvoiceDelete('billing.invoice_delete'),
  billingInvoiceResend('billing.invoice_resend'),
  billingPaymentMethodUpdate('billing.payment_method_update'),
  billingPaymentMethodSetPrimary('billing.payment_method_set_primary'),
  billingAutopayMethodSet('billing.autopay_method_set'),

  /// The card form in the autopay WebView handing back a token, logged by
  /// the screen that opened it. Failed means no token came back.
  billingCardTokenize('billing.card_tokenize'),
  billingCreditCreate('billing.credit_create'),
  billingDiscountCreate('billing.discount_create'),
  billingDiscountUpdate('billing.discount_update'),
  billingDiscountDelete('billing.discount_delete'),
  billingDiscountDeactivate('billing.discount_deactivate'),
  billingDiscountReactivate('billing.discount_reactivate'),
  billingLedgerCreate('billing.ledger_create'),
  billingLedgerUpdate('billing.ledger_update'),
  billingLedgerDelete('billing.ledger_delete'),
  billingLedgerDeactivate('billing.ledger_deactivate'),
  billingLedgerReactivate('billing.ledger_reactivate'),
  billingLedgerTransactionAdd('billing.ledger_transaction_add'),
  studentCreate('student.create'),
  studentProfileUpdate('student.profile_update'),
  studentAddressUpdate('student.address_update'),
  studentHealthUpdate('student.health_update'),
  studentImmunizationUpdate('student.immunization_update'),
  studentImportantDatesUpdate('student.important_dates_update'),
  studentSchedulesUpdate('student.schedules_update'),
  studentTagsUpdate('student.tags_update'),
  studentSiblingAdd('student.sibling_add'),
  studentSiblingsUpdate('student.siblings_update'),
  studentPhysicalExamAdd('student.physical_exam_add'),
  studentPhysicalExamUpdate('student.physical_exam_update'),
  studentDocumentAdd('student.document_add'),
  studentDocumentUpdate('student.document_update'),
  studentDocumentDelete('student.document_delete'),
  studentPhysicianAdd('student.physician_add'),
  studentPhysicianUpdate('student.physician_update'),
  studentPhysicianDelete('student.physician_delete'),
  studentPickupAdd('student.pickup_add'),
  studentPickupUpdate('student.pickup_update'),
  studentPickupDelete('student.pickup_delete'),

  /// count is the number of students moved.
  studentClassroomAssign('student.classroom_assign'),

  /// A login email change. Shared by the staff and guardian edit flows; the
  /// persona tag on the line tells them apart.
  userEmailChange('user.email_change'),
  guardianCreate('guardian.create'),
  guardianLink('guardian.link'),
  guardianUpdate('guardian.update'),
  guardianDelete('guardian.delete'),
  guardianInviteResend('guardian.invite_resend'),
  guardianPinGenerate('guardian.pin_generate'),
  guardianPinChange('guardian.pin_change'),

  /// A guardian editing their own profile.
  guardianProfileUpdate('guardian.profile_update'),
  staffCreate('staff.create'),
  staffActivate('staff.activate'),
  staffDeactivate('staff.deactivate'),
  staffDelete('staff.delete'),
  staffOrgAdminActivate('staff.org_admin_activate'),
  staffOrgAdminDeactivate('staff.org_admin_deactivate'),
  staffProfileUpdate('staff.profile_update'),

  /// A staff member editing their own profile.
  staffOwnProfileUpdate('staff.own_profile_update'),
  staffAddressUpdate('staff.address_update'),
  staffImportantDatesUpdate('staff.important_dates_update'),
  staffSchedulesUpdate('staff.schedules_update'),
  staffAllowedClassroomsUpdate('staff.allowed_classrooms_update'),
  staffPrimaryClassroomUpdate('staff.primary_classroom_update'),
  staffDocumentAdd('staff.document_add'),
  staffDocumentUpdate('staff.document_update'),
  staffDocumentDelete('staff.document_delete'),

  /// count is the number of staff moved.
  staffClassroomAssign('staff.classroom_assign'),

  /// count is the number of shifts the server created for the repeat rule.
  schedulingShiftCreate('scheduling.shift_create'),
  schedulingShiftUpdate('scheduling.shift_update'),
  schedulingShiftSeriesUpdate('scheduling.shift_series_update'),
  schedulingShiftDelete('scheduling.shift_delete'),
  schedulingShiftSeriesDelete('scheduling.shift_series_delete'),
  schedulingShiftPublish('scheduling.shift_publish'),
  availabilityMovementCreate('availability.movement_create'),
  availabilityMovementUpdate('availability.movement_update'),
  availabilityMovementDelete('availability.movement_delete'),
  availabilityMovementStatusChange('availability.movement_status_change'),
  classroomLogoUpload('classroom.logo_upload'),

  /// Opening a conversation, which creates it on first contact.
  communicationConversationOpen('communication.conversation_open'),

  /// count is the number of attachments.
  communicationMessageSend('communication.message_send'),
  communicationMessageEdit('communication.message_edit'),
  communicationMessageDelete('communication.message_delete'),
  communicationAttachmentDelete('communication.attachment_delete'),
  communicationReactionAdd('communication.reaction_add'),
  communicationReactionRemove('communication.reaction_remove'),
  communicationPrivateModeToggle('communication.private_mode_toggle'),
  kioskPinVerify('kiosk.pin_verify'),
  kioskStaffSignIn('kiosk.staff_sign_in'),
  kioskStaffSignOut('kiosk.staff_sign_out'),

  /// This device's FCM token registered with, or removed from, the backend.
  notificationPushRegister('notification.push_register'),
  notificationPushUnregister('notification.push_unregister'),
  notificationMarkAllRead('notification.mark_all_read'),
  notificationPreferencesUpdate('notification.preferences_update'),

  /// Failed with `permission` when the user or OS denied it.
  geofencePermissionRequest('geofence.permission_request'),
  reportGenerate('report.generate'),
  reportDownload('report.download'),

  /// Writing a downloaded report to the device.
  reportSave('report.save'),
  appUpdateDismiss('app.update_dismiss'),

  /// Failed means the store could not be opened.
  appStoreOpen('app.store_open');

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

  /// The user or the OS denied a device permission (location, camera,
  /// notifications).
  permission,

  /// A device capability was off or gave no answer, e.g. location services
  /// disabled or no GPS fix.
  unavailable,
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
    final succeeded = outcome == EventOutcome.succeeded;
    final attributes = <String, Object>{
      'event': event.key,
      'outcome': outcome.name,
      if (failure != null) 'failure': failure.name,
      if (count != null) 'count': count,
      if (durationMs != null) 'duration_ms': durationMs,
    };
    AppLogger.event(name, succeeded: succeeded, attributes: attributes);
    Telemetry.log(
      name,
      level: succeeded ? TelemetryLogLevel.info : TelemetryLogLevel.warn,
      attributes: attributes,
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

  /// A [track] `failureOf` for operations that return a dartz [Either]: a
  /// left is bucketed by [EventFailure.of], a right is a success.
  static EventFailure? leftFailure<L, R>(Either<L, R> result) =>
      result.fold(EventFailure.of, (_) => null);

  /// Runs [operation] and logs its outcome with its duration. A throw is
  /// logged as failed and rethrown untouched.
  ///
  /// For operations that report failure in their result instead of throwing
  /// (an `Either`, a `success` flag), [failureOf] returns the bucket for a
  /// failed result and null for a good one.
  ///
  /// [countOf] reads the count from a successful result, for when only the
  /// server knows it (shifts created by a repeat rule). It wins over [count].
  static Future<T> track<T>(
    AppEvent event,
    Future<T> Function() operation, {
    int? count,
    int? Function(T result)? countOf,
    EventFailure? Function(T result)? failureOf,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      final failure = failureOf?.call(result);
      final durationMs = stopwatch.elapsedMilliseconds;
      if (failure == null) {
        succeeded(
          event,
          count: countOf?.call(result) ?? count,
          durationMs: durationMs,
        );
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
