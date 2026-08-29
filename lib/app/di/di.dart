import 'package:wowcare/core/util/logger_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/features/notifications/datasources/fcm_registration_remote_data_source.dart';
import '../../data/features/notifications/datasources/fcm_remote_data_source.dart';
import '../../data/features/notifications/datasources/notification_center_data_source.dart';
import '../../data/features/notifications/datasources/notification_center_remote_data_source.dart';
import '../../data/features/notifications/datasources/notification_inbox_remote_data_source.dart';
import '../../data/features/notifications/datasources/notification_preference_groups_remote_data_source.dart';
import '../../data/features/notifications/repositories/fcm_registration_repository_impl.dart';
import '../../data/features/notifications/repositories/notification_preference_groups_repository_impl.dart';
import '../../data/features/notifications/repositories/notification_center_repository_impl.dart';
import '../../data/features/notifications/repositories/push_notification_repository_impl.dart';
import '../../data/features/notifications/services/fcm_token_registration_service.dart';
import '../../domain/features/notifications/repositories/fcm_registration_repository.dart';
import '../../domain/features/notifications/repositories/notification_center_repository.dart';
import '../../domain/features/notifications/repositories/notification_preference_groups_repository.dart';
import '../../domain/features/notifications/repositories/push_notification_repository.dart';
import '../../domain/features/notifications/usecases/get_notification_preference_groups_usecase.dart';
import '../../domain/features/notifications/usecases/get_notification_unread_counts_usecase.dart';
import '../../domain/features/notifications/usecases/get_notifications_usecase.dart';
import '../../domain/features/notifications/usecases/update_notification_preference_groups_usecase.dart';
import '../../domain/features/notifications/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/features/notifications/usecases/mark_notification_read_usecase.dart';
import '../../domain/features/notifications/usecases/register_device_fcm_token_usecase.dart';
import '../../domain/features/notifications/usecases/unregister_device_fcm_token_usecase.dart';
import '../../data/features/notifications/realtime/notification_realtime_data_source.dart';
import '../../presentation/features/notifications/cubit/notification_badge_cubit.dart';
import '../../presentation/features/notifications/cubit/notification_center_cubit.dart';
import '../../presentation/features/notifications/cubit/push_notification_cubit.dart';
import '../../presentation/features/user-profile/view_model/notification_preference_groups_cubit.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/network_info.dart';
import '../../core/network/session_expired_interceptor.dart';
import '../../core/storage/storage_service.dart';
import '../../core/auth/secure_credential_store.dart';
import '../../core/util/api_constants.dart';
import '../../core/cache/cache_service.dart';
import '../../core/cache/isar_cache_service.dart';
import '../../data/features/auth/datasources/auth_local_datasource.dart';
import '../../data/features/auth/datasources/auth_remote_datasource.dart';
import '../../data/features/auth/repositories/auth_repository_impl.dart';
import '../../data/features/onboarding/datasources/onboarding_remote_datasource.dart';
import '../../data/features/classroom/datasources/classroom_remote_datasource.dart';
import '../../data/features/classroom/repositories/classroom_repository_impl.dart';
import '../../data/features/onboarding/repositories/onboarding_repository_impl.dart';
import '../../data/features/staff/datasources/staff_remote_datasource.dart';
import '../../data/features/staff/repositories/staff_repository_impl.dart';
import '../../data/features/student/datasources/student_remote_datasource.dart';
import '../../data/features/student/repositories/student_repository_impl.dart';
import '../../data/features/attendance/datasources/attendance_remote_datasource.dart';
import '../../data/features/attendance/repositories/attendance_repository_impl.dart';
import '../../data/features/availability/datasources/availability_remote_datasource.dart';
import '../../data/features/availability/repositories/availability_repository_impl.dart';
import '../../data/features/scheduling/datasources/staff_shift_remote_datasource.dart';
import '../../data/features/scheduling/repositories/staff_shift_repository_impl.dart';
import '../../core/util/cache_manager.dart';
import '../../domain/features/scheduling/repositories/staff_shift_repository.dart';
import '../../domain/features/scheduling/usecases/create_staff_shift_usecase.dart';
import '../../domain/features/scheduling/usecases/delete_staff_shift_series_usecase.dart';
import '../../domain/features/scheduling/usecases/delete_staff_shift_usecase.dart';
import '../../domain/features/scheduling/usecases/update_staff_shift_series_usecase.dart';
import '../../domain/features/scheduling/usecases/update_staff_shift_usecase.dart';
import '../../domain/features/scheduling/usecases/get_staff_shift_by_code_usecase.dart';
import '../../domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';
import '../../domain/features/scheduling/usecases/get_classroom_forecast_range_usecase.dart';
import '../../domain/features/scheduling/usecases/get_classroom_forecast_usecase.dart';
import '../../domain/features/scheduling/usecases/get_staff_shift_hours_range_usecase.dart';
import '../../domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
import '../../domain/features/scheduling/usecases/publish_staff_shifts_usecase.dart';
import '../../domain/features/auth/repositories/auth_repository.dart';
import '../../domain/features/auth/usecases/login_usecase.dart';
import '../../domain/features/auth/usecases/forgot_password_usecase.dart';
import '../../domain/features/classroom/repositories/classroom_repository.dart';
import '../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import '../../domain/features/classroom/usecases/get_school_capacity_usecase.dart';
import '../../domain/features/classroom/usecases/get_classroom_count_usecase.dart';
import '../../domain/features/classroom/usecases/get_school_fte_usecase.dart';
import '../../domain/features/onboarding/repositories/onboarding_repository.dart';
import '../../domain/features/onboarding/usecases/get_onboarding_content.dart';
import '../../presentation/features/billing/cubit/parent_billing_cubit.dart';
import '../../presentation/features/onboarding/view_model/onboarding_cubit.dart';
import '../../presentation/features/user-profile/view_model/profile_menu_header_cubit.dart';
import '../../presentation/features/reports/cubit/reports_cubit.dart';
import '../../data/features/reports/datasources/reports_remote_datasource.dart';
import '../../data/features/reports/datasources/reports_remote_datasource_impl.dart';
import '../../data/features/reports/repositories/reports_repository_impl.dart';
import '../../domain/features/reports/repositories/reports_repository.dart';
import '../../domain/features/reports/usecases/generate_report_usecase.dart';
import '../../domain/features/reports/usecases/get_recent_reports_usecase.dart';
import '../../domain/features/reports/usecases/get_student_tags_usecase.dart';
import '../../domain/features/reports/usecases/download_report_usecase.dart';
import '../../presentation/features/user-profile/view_model/edit_user_profile_cubit.dart';
import '../../presentation/features/user-profile/view_model/user_profile_cubit.dart';
import '../../domain/features/staff/repositories/staff_repository.dart';
import '../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../domain/features/staff/usecases/get_all_staff_usecase.dart';
import '../../data/features/scheduling/datasources/staff_scheduling_remote_datasource.dart';
import '../../data/features/scheduling/repositories/staff_scheduling_repository_impl.dart';
import '../../domain/features/scheduling/repositories/staff_scheduling_repository.dart';
import '../../domain/features/staff/usecases/get_staff_shifts_usecase.dart';
import '../../presentation/features/scheduling/cubit/scheduling_cubit.dart';
import '../../presentation/features/scheduling/cubit/staff_scheduling_cubit.dart';
import '../../presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import '../../presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import '../../presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import '../../presentation/features/dashboard/cubit/qr_validation_cubit.dart';
import '../../presentation/features/dashboard/cubit/school_status_cubit.dart';
import '../../presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import '../../presentation/features/dashboard/cubit/admin_dashboard_cubit.dart';
import '../../presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import '../../presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import '../../presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import '../../presentation/features/dashboard/cubit/my_day_cubit.dart';
import '../../presentation/features/dashboard/cubit/work_break_reminder_cubit.dart';
import '../../presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import '../../presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import '../../presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
import '../../presentation/features/dashboard/services/dashboard_cubit_factory.dart';
import '../../presentation/features/dashboard/cubit/parent_dashboard_coordinator_cubit.dart';
import '../../presentation/features/dashboard/cubit/staff_dashboard_coordinator_cubit.dart';
import '../../presentation/features/dashboard/cubit/admin_dashboard_coordinator_cubit.dart';
import '../../domain/features/classroom/usecases/get_ratio_monitoring_classrooms_usecase.dart';
import '../../domain/features/attendance/usecases/validate_qr_code_usecase.dart';
import '../../domain/features/kiosk/repositories/kiosk_repository.dart';
import '../../domain/features/kiosk/usecases/get_active_kiosk_qr_usecase.dart';
import '../../domain/features/kiosk/usecases/verify_kiosk_pin_usecase.dart';
import '../../data/features/kiosk/datasources/kiosk_remote_datasource.dart'; // For QR/PIN features
import '../../data/features/kiosk/repositories/kiosk_repository_impl.dart';
// REFACTORED KIOSK MODULE - CLEAN ARCHITECTURE
import '../../data/features/kiosk/datasources/kiosk_attendance_remote_datasource.dart';
import '../../presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
// REFACTORED KIOSK MODULE - CLEAN ARCHITECTURE
import '../../domain/features/kiosk/repositories/kiosk_attendance_repository.dart';
import '../../domain/features/kiosk/usecases/sign_in_staff_usecase.dart';
import '../../domain/features/kiosk/usecases/sign_out_staff_usecase.dart';
import '../../data/features/kiosk/repositories/kiosk_attendance_repository_impl.dart';
import '../../presentation/features/kiosk/cubit/kiosk_attendance_cubit_v2.dart';
import '../../presentation/features/kiosk/cubit/kiosk_logout_cubit.dart';
import '../../presentation/features/kiosk/utils/kiosk_access_control.dart';
import '../../presentation/features/scheduling/cubit/publish_shifts_cubit.dart';
import '../../presentation/features/scheduling/cubit/add_shift_cubit.dart';
import '../../presentation/features/scheduling/cubit/edit_shift_cubit.dart';
import '../../domain/features/staff/usecases/get_staff_count_usecase.dart';
import '../../domain/features/staff/usecases/add_staff_document_usecase.dart';
import '../../domain/features/staff/usecases/update_staff_document_usecase.dart';
import '../../domain/features/staff/usecases/delete_staff_document_usecase.dart';
import '../../domain/features/staff/usecases/get_staff_documents_usecase.dart';
import '../../domain/features/staff/usecases/get_staff_profile_usecase.dart';
import '../../domain/features/staff/usecases/get_important_dates_usecase.dart';
import '../../domain/features/staff/usecases/update_important_dates_usecase.dart';
import '../../domain/features/staff/usecases/create_school_user_usecase.dart';
import '../../domain/features/student/repositories/student_repository.dart';
import '../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../domain/features/student/usecases/get_student_counts_usecase.dart';
import '../../domain/features/student_classroom/repositories/student_classroom_repository.dart';
import '../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../../domain/features/student_classroom/usecases/assign_students_to_classroom_usecase.dart';
import '../../data/features/student_classroom/datasources/student_classroom_remote_datasource.dart';
import '../../data/features/student_classroom/repositories/student_classroom_repository_impl.dart';
import '../../domain/features/staff_classroom/repositories/staff_classroom_repository.dart';
import '../../domain/features/staff_classroom/usecases/get_staff_classrooms_usecase.dart';
import '../../domain/features/staff_classroom/usecases/assign_staff_to_classroom_usecase.dart';
import '../../data/features/staff_classroom/datasources/staff_classroom_remote_datasource.dart';
import '../../data/features/staff_classroom/repositories/staff_classroom_repository_impl.dart';
import '../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import '../../domain/features/availability/repositories/availability_repository.dart';
import '../../domain/features/availability/usecases/create_individual_movement_usecase.dart';
import '../../domain/features/availability/usecases/delete_individual_movement_usecase.dart';
import '../../domain/features/availability/usecases/get_future_availability_usecase.dart';
import '../../domain/features/availability/usecases/get_individual_movement_by_id_usecase.dart';
import '../../domain/features/availability/usecases/get_individual_movements_usecase.dart';
import '../../domain/features/availability/usecases/transition_individual_movement_status_usecase.dart';
import '../../domain/features/availability/usecases/update_individual_movement_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_absent_records_activity_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_absent_toggle_view_usecase.dart';
import '../../domain/features/attendance/usecases/mark_students_absent_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_daily_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_custom_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_absent_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_absent_toggle_view_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_sign_out_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/mark_staff_absent_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import '../../domain/features/attendance/usecases/update_student_attendance_record_usecase.dart';
import '../../domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_submit_cubit.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_gate_cubit.dart';
import '../../presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_gate_cubit.dart';
import '../../domain/features/attendance/usecases/submit_student_sign_out_usecase.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_out_submit_cubit.dart';
import '../../domain/features/attendance/usecases/submit_student_transfer_usecase.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_transfer_submit_cubit.dart';
import '../../domain/features/attendance/usecases/submit_staff_sign_in_usecase.dart';
import '../../presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_submit_cubit.dart';
import '../../domain/features/attendance/usecases/submit_staff_sign_out_usecase.dart';
import '../../presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_out_submit_cubit.dart';
import '../../domain/features/attendance/usecases/submit_staff_transfer_usecase.dart';
import '../../presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_transfer_submit_cubit.dart';
import '../../domain/features/attendance/usecases/delete_staff_attendance_record_usecase.dart';
import '../../domain/features/attendance/usecases/delete_student_attendance_record_usecase.dart';
import '../../domain/features/attendance/usecases/delete_student_absence_record_usecase.dart';
import '../../domain/features/attendance/usecases/delete_staff_absence_record_usecase.dart';
import '../../domain/features/attendance/usecases/fetch_student_attendance_profile_usecase.dart';
import '../../domain/features/attendance/usecases/fetch_student_attendance_profile_absent_toggle_usecase.dart';
import '../../domain/features/attendance/usecases/fetch_staff_attendance_profile_usecase.dart';
import '../../domain/features/attendance/usecases/fetch_staff_attendance_profile_absent_toggle_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_absent_view_usecase.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_delete_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_delete_cubit.dart';
import '../../domain/features/student/usecases/get_student_documents_usecase.dart';
import '../../domain/features/student/usecases/add_student_document_usecase.dart';
import '../../domain/features/student/usecases/get_student_important_dates_usecase.dart';
import '../../domain/features/student/usecases/update_student_important_dates_usecase.dart';
import '../../domain/features/student/usecases/update_student_document_usecase.dart';
import '../../domain/features/student/usecases/delete_student_document_usecase.dart';
import '../../domain/features/student/usecases/get_student_physicians_usecase.dart';
import '../../domain/features/student/usecases/add_physician_usecase.dart';
import '../../domain/features/student/usecases/update_physician_usecase.dart';
import '../../domain/features/student/usecases/delete_physician_usecase.dart';
import '../../domain/features/student/usecases/get_student_pickups_usecase.dart';
import '../../domain/features/student/usecases/add_pickup_usecase.dart';
import '../../domain/features/student/usecases/update_pickup_usecase.dart';
import '../../domain/features/student/usecases/delete_pickup_usecase.dart';
import '../../domain/features/student/usecases/get_guardians_raw_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_student_guardians_usecase.dart';
import '../../domain/features/student/usecases/delete_guardian_usecase.dart';
import '../../domain/features/student/usecases/get_student_health_usecase.dart';
import '../../domain/features/student/usecases/update_student_health_usecase.dart';
import '../../domain/features/student/usecases/get_student_immunizations_usecase.dart';
import '../../domain/features/student/usecases/update_student_immunization_record_usecase.dart';
import '../../domain/features/student/usecases/get_student_physical_exams_usecase.dart';
import '../../domain/features/student/usecases/add_student_physical_exam_usecase.dart';
import '../../domain/features/student/usecases/update_student_physical_exam_usecase.dart';
import '../../domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_student_codes_for_activity_tag_filter_usecase.dart';
import '../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_student_tag_names_usecase.dart';
import '../../domain/features/student/usecases/update_student_tags_usecase.dart';
import '../../presentation/features/billing/cubit/select_students_cubit.dart';
import '../../domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_immunization_settings_usecase.dart';
import '../../domain/features/student/usecases/get_vaccine_name_to_code_map_for_school_usecase.dart';
import '../../domain/features/activity/repositories/activity_repository.dart';
import '../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../domain/features/activity/usecases/get_active_activity_types_for_school_usecase.dart';
import '../../presentation/features/activities/cubit/activity_filter_cubit.dart';
import '../../presentation/features/activities/cubit/activity_student_selection_cubit.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_selection_cubit.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_out_selection_cubit.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_transfer_selection_cubit.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_mark_absent_selection_cubit.dart';
import '../../presentation/features/activities/cubit/activity_editor_cubit.dart';
import '../../presentation/features/activities/cubit/activity_moderation_cubit.dart';
import '../../presentation/features/activities/cubit/medication_activity_cubit.dart';
import '../../presentation/features/activities/cubit/bottle_activity_cubit.dart';
import '../../presentation/features/activities/cubit/nap_activity_cubit.dart';
import '../../presentation/features/activities/cubit/incident_activity_cubit.dart';
import '../../presentation/features/activities/cubit/activity_feed_scope_cubit.dart';
import '../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../domain/features/activity/usecases/create_shared_activities_usecase.dart';
import '../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../domain/features/activity/usecases/delete_activity_usecase.dart';
import '../../domain/features/activity/usecases/approve_activity_usecase.dart';
import '../../domain/features/activity/usecases/acknowledge_activity_usecase.dart';
import '../../domain/features/activity/usecases/guardian_parent_signature_usecase.dart';
import '../../domain/features/activity/usecases/reject_activity_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_upload_sessions_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_asset_presign_usecase.dart';
import '../../domain/features/activity/usecases/get_daily_activity_feed_usecase.dart';
import '../../domain/features/activity/usecases/get_range_activity_feed_usecase.dart';
import '../../domain/features/activity/usecases/get_nap_start_students_usecase.dart';
import '../../data/features/activity/datasources/activity_remote_datasource.dart';
import '../../data/features/activity/repositories/activity_repository_impl.dart';
import '../../presentation/features/auth/cubit/auth_cubit.dart';
import '../../presentation/features/classroom/cubit/classroom_cubit.dart';
import '../../presentation/features/classroom/cubit/classroom_students_cubit.dart';
import '../../presentation/features/classroom/cubit/classroom_staff_cubit.dart';
import '../../presentation/features/staff/cubit/staff_cubit.dart';
import '../../presentation/features/staff/cubit/staff_document_cubit.dart';
import '../../presentation/features/staff/cubit/staff_documents_list_cubit.dart';
import '../../presentation/features/staff/cubit/staff_profile_cubit.dart';
import '../../presentation/features/staff/cubit/important_dates_cubit.dart';
import '../../presentation/features/staff/cubit/create_school_user_cubit.dart';
import '../../presentation/features/students/cubit/student_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_daily_cubit.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_mark_absent_cubit.dart';
import '../../presentation/features/attendance/forms/student_attendance_forms/cubit/student_edit_attendance_cubit.dart';
import '../../presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_mark_absent_cubit.dart';
import '../../presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_edit_attendance_cubit.dart';
import '../../presentation/features/availability/cubit/future_availability_cubit.dart';
import '../../presentation/features/availability/cubit/individual_movements_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_custom_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_absent_toggle_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_daily_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_custom_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_absent_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_absent_toggle_cubit.dart';
import '../../presentation/features/students/cubit/student_documents_list_cubit.dart';
import '../../presentation/features/students/cubit/student_physician_cubit.dart';
import '../../presentation/features/students/cubit/student_tags_cubit.dart';
import '../../presentation/features/students/cubit/student_pickup_cubit.dart';
import '../../presentation/features/students/cubit/student_guardian_cubit.dart';
import '../../presentation/features/students/cubit/student_health_cubit.dart';
import '../../presentation/features/students/cubit/student_physical_exam_cubit.dart';
import '../../presentation/features/students/cubit/student_document_cubit.dart';
import '../../presentation/features/students/cubit/student_important_dates_cubit.dart';
import '../../domain/features/communication/repositories/communication_repository.dart';
import '../../domain/features/communication/usecases/get_messages_usecase.dart';
import '../../domain/features/communication/usecases/send_message_usecase.dart';
import '../../domain/features/communication/usecases/create_conversation_usecase.dart';
import '../../domain/features/communication/usecases/get_conversations_usecase.dart';
import '../../domain/features/communication/usecases/get_cached_conversations_usecase.dart';
import '../../domain/features/communication/usecases/get_cached_messages_usecase.dart';
import '../../domain/features/communication/usecases/cache_message_usecase.dart';
import '../../domain/features/communication/usecases/add_reaction_usecase.dart';
import '../../domain/features/communication/usecases/edit_message_usecase.dart';
import '../../domain/features/communication/usecases/clear_cache_usecase.dart';
import '../../domain/features/communication/usecases/delete_message_usecase.dart';
import '../../domain/features/communication/usecases/delete_attachment_usecase.dart';
import '../../domain/features/communication/usecases/remove_reaction_legacy_usecase.dart';
import '../../domain/features/communication/usecases/watch_messages_legacy_usecase.dart';
import '../../domain/features/communication/usecases/watch_conversations_legacy_usecase.dart';
import '../../domain/features/communication/usecases/mark_conversation_delivered_usecase.dart';
import '../../data/features/communication/datasources/communication_remote_data_source.dart';
import '../../data/features/communication/repositories/communication_repository_impl.dart';
// Communication v2.1 — Phase 1B
import '../../domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import '../../domain/features/communication/usecases/get_conversation_entity_usecase.dart';
import '../../domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import '../../domain/features/communication/usecases/create_conversation_entity_usecase.dart';
import '../../domain/features/communication/usecases/get_conversations_for_student_usecase.dart';
import '../../domain/features/communication/usecases/get_conversations_for_classroom_usecase.dart';
import '../../domain/features/communication/usecases/get_or_create_classroom_chat_usecase.dart';
import '../../domain/features/communication/usecases/get_classroom_roster_present_user_codes_usecase.dart';
import '../../domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import '../../domain/features/communication/usecases/mark_conversation_read_usecase.dart';
import '../../domain/features/communication/usecases/get_unread_counts_per_conversation_usecase.dart';
import '../../domain/features/communication/usecases/get_message_receipts_usecase.dart';
import '../../domain/features/communication/usecases/get_messages_entity_usecase.dart';
import '../../domain/features/communication/usecases/get_cached_messages_entity_usecase.dart';
import '../../domain/features/communication/usecases/send_message_entity_usecase.dart';
import '../../domain/features/communication/usecases/cache_draft_message_usecase.dart';
import '../../domain/features/communication/usecases/mark_draft_message_failed_usecase.dart';
import '../../domain/features/communication/usecases/edit_message_entity_usecase.dart';
import '../../domain/features/communication/usecases/delete_message_entity_usecase.dart';
import '../../domain/features/communication/usecases/delete_attachment_entity_usecase.dart';
import '../../domain/features/communication/usecases/get_message_entity_receipts_usecase.dart';
import '../../domain/features/communication/usecases/search_messages_usecase.dart';
import '../../domain/features/communication/usecases/add_reaction_entity_usecase.dart';
import '../../domain/features/communication/usecases/remove_reaction_usecase.dart';
import '../../domain/features/communication/usecases/sync_pending_operations_usecase.dart';
import '../../domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import '../../domain/features/communication/repositories/reaction_repository.dart';
import '../../data/features/communication/repositories/reaction_repository_impl.dart';
import '../../data/features/communication/datasources/conversation_entity_remote_data_source.dart';
import '../../data/features/communication/datasources/conversation_entity_local_data_source.dart';
import '../../data/features/communication/datasources/message_entity_remote_data_source.dart';
import '../../data/features/communication/datasources/message_entity_local_data_source.dart';
import '../../data/features/communication/repositories/conversation_entity_repository_impl.dart';
import '../../data/features/communication/repositories/message_entity_repository_impl.dart';
import '../../domain/features/communication/repositories/conversation_entity_repository.dart';
import '../../domain/features/communication/repositories/message_entity_repository.dart';
import '../../data/features/communication/realtime/conversation_realtime_data_source.dart';
import '../../data/features/communication/realtime/message_realtime_data_source.dart';
import '../../data/features/communication/realtime/firebase_token_data_source.dart';
import '../../core/firebase/firebase_auth_service.dart';
import '../../domain/features/communication/usecases/watch_conversations_usecase.dart';
import '../../domain/features/communication/usecases/watch_total_unread_count_usecase.dart';
import '../../domain/features/communication/usecases/watch_messages_usecase.dart';
import '../../domain/features/communication/usecases/watch_unread_count_for_type_usecase.dart';
import '../../domain/features/communication/usecases/register_firebase_token_usecase.dart';
import '../../presentation/features/communication/cubit/unread_badge_cubit.dart';
import '../../data/features/newsletter/datasources/student_newsletters_remote_datasource.dart';
import '../../data/features/newsletter/repositories/student_newsletters_repository_impl.dart';
import '../../data/features/newsletter/datasources/newsletter_remote_datasource.dart';
import '../../data/features/newsletter/repositories/newsletter_repository_impl.dart';
import '../../domain/features/newsletter/repositories/newsletter_repository.dart';
import '../../domain/features/newsletter/usecases/get_sent_newsletters_usecase.dart';
import '../../domain/features/newsletter/usecases/get_newsletter_by_code_usecase.dart';
import '../../presentation/features/newsletter/cubit/newsletter_list_cubit.dart';
import '../../presentation/features/newsletter/cubit/preview_newsletter_cubit.dart';
import '../../core/cache/session_local_cache_wiper.dart';
import '../../presentation/features/communication/cubit/communication_cubit.dart';
import '../../presentation/features/communication/shared/utils/chat_attachment_uploader.dart';
import '../../presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import '../../shared/services/image_upload/image_upload_service.dart';
import '../../shared/services/image_upload/profile_photo_uploader.dart';
import '../../domain/features/newsletter/repositories/student_newsletters_repository.dart';
import '../../domain/features/newsletter/usecases/get_student_newsletters_usecase.dart';
import '../../domain/features/student/usecases/get_student_profile_usecase.dart';
import '../../data/features/geofencing/datasources/geofencing_local_datasource.dart';
import '../../data/features/geofencing/repositories/geofencing_repository_impl.dart';
import '../../domain/features/geofencing/repositories/geofencing_repository.dart';
import '../../domain/features/geofencing/usecases/check_location_permission_usecase.dart';
import '../../domain/features/geofencing/usecases/request_location_permission_usecase.dart';
import '../../domain/features/geofencing/usecases/get_school_location_usecase.dart';
import '../../domain/features/geofencing/usecases/watch_geofence_usecase.dart';
import '../../presentation/features/geofencing/cubit/geofence_cubit.dart';
import '../../shared/common/app/cubit/parent_child_cubit.dart';
import '../../shared/services/geofence_notification_service.dart';
import '../../data/services/file_download_service.dart';
import '../../data/features/reports/repositories/file_download_repository.dart';
import '../../data/features/billing/datasources/billing_statements_remote_datasource.dart';
import '../../data/features/billing/datasources/ledger_remote_datasource.dart';
import '../../data/features/billing/datasources/ledger_transaction_remote_datasource.dart';
import '../../data/features/billing/repositories/billing_statements_repository_impl.dart';
import '../../data/features/billing/repositories/ledger_repository_impl.dart';
import '../../data/features/billing/repositories/ledger_transaction_repository_impl.dart';
import '../../domain/features/billing/repositories/billing_statements_repository.dart';
import '../../domain/features/billing/usecases/get_billing_statements_usecase.dart';
import '../../presentation/features/billing/cubit/admin_statements_cubit.dart';
import '../../presentation/features/billing/cubit/parent_statements_cubit.dart';
import '../../domain/features/billing/repositories/ledger_repository.dart';
import '../../domain/features/billing/repositories/ledger_transaction_repository.dart';
import '../../domain/features/billing/usecases/get_ledgers_usecase.dart';
import '../../domain/features/billing/usecases/create_ledger_usecase.dart';
import '../../domain/features/billing/usecases/get_ledger_by_code_usecase.dart';
import '../../domain/features/billing/usecases/delete_ledger_usecase.dart';
import '../../domain/features/billing/usecases/update_ledger_usecase.dart';
import '../../domain/features/billing/usecases/deactivate_ledger_usecase.dart';
import '../../domain/features/billing/usecases/reactivate_ledger_usecase.dart';
import '../../domain/features/billing/usecases/get_ledger_transactions_usecase.dart';
import '../../domain/features/billing/usecases/add_ledger_transaction_usecase.dart';
import '../../presentation/features/billing/cubit/general_ledger_cubit.dart';
import '../../presentation/features/billing/cubit/ledger_detail_cubit.dart';
import '../../data/features/billing/datasources/discount_remote_datasource.dart';
import '../../data/features/billing/repositories/discount_repository_impl.dart';
import '../../domain/features/billing/repositories/discount_repository.dart';
import '../../domain/features/billing/usecases/get_discounts_usecase.dart';
import '../../data/features/billing/datasources/invoice_catalog_remote_datasource.dart';
import '../../data/features/billing/repositories/invoice_catalog_repository_impl.dart';
import '../../domain/features/billing/repositories/invoice_catalog_repository.dart';
import '../../domain/features/billing/usecases/get_fee_structures_usecase.dart';
import '../../domain/features/billing/usecases/get_other_fees_usecase.dart';
import '../../domain/features/billing/usecases/get_subsidies_usecase.dart';
import '../../data/features/billing/datasources/invoice_remote_datasource.dart';
import '../../data/features/billing/repositories/invoice_repository_impl.dart';
import '../../domain/features/billing/repositories/invoice_repository.dart';
import '../../domain/features/billing/usecases/create_invoice_usecase.dart';
import '../../domain/features/billing/usecases/update_invoice_usecase.dart';
import '../../domain/features/billing/usecases/delete_invoice_usecase.dart';
import '../../domain/features/billing/usecases/cancel_invoice_usecase.dart';
import '../../domain/features/billing/usecases/issue_invoice_usecase.dart';
import '../../domain/features/billing/usecases/resend_invoice_usecase.dart';
import '../../domain/features/billing/usecases/check_invoice_recipients_usecase.dart';
import '../../domain/features/billing/usecases/get_invoice_overview_usecase.dart';
import '../../domain/features/billing/usecases/get_invoice_transactions_usecase.dart';
import '../../domain/features/billing/usecases/get_invoices_usecase.dart';
import '../../domain/features/billing/usecases/get_invoice_by_code_usecase.dart';
import '../../domain/features/billing/usecases/get_family_summary_usecase.dart';
import '../../domain/features/billing/usecases/get_family_ledger_usecase.dart';
import '../../domain/features/billing/usecases/create_payment_usecase.dart';
import '../../domain/features/billing/usecases/create_refund_usecase.dart';
import '../../domain/features/billing/usecases/create_credit_usecase.dart';
import '../../presentation/features/billing/cubit/create_invoice_cubit.dart';
import '../../presentation/features/billing/cubit/transactions_cubit.dart';
import '../../presentation/features/billing/cubit/family_summary_cubit.dart';
import '../../presentation/features/billing/cubit/transaction_details_cubit.dart';
import '../../presentation/features/billing/cubit/receive_payment_refund_cubit.dart';
import '../../presentation/features/billing/cubit/add_credit_cubit.dart';
import '../../data/features/billing/datasources/auto_pay_remote_datasource.dart';
import '../../data/features/billing/repositories/auto_pay_repository_impl.dart';
import '../../domain/features/billing/repositories/auto_pay_repository.dart';
import '../../domain/features/billing/usecases/get_school_forte_config_usecase.dart';
import '../../domain/features/billing/usecases/get_payment_settings_usecase.dart';
import '../../domain/features/billing/usecases/get_autopay_status_usecase.dart';
import '../../domain/features/billing/usecases/set_autopay_status_usecase.dart';
import '../../domain/features/billing/usecases/get_payment_methods_usecase.dart';
import '../../domain/features/billing/usecases/add_payment_method_usecase.dart';
import '../../domain/features/billing/usecases/set_primary_payment_method_usecase.dart';
import '../../domain/features/billing/usecases/set_autopay_method_usecase.dart';
import '../../domain/features/billing/usecases/delete_payment_method_usecase.dart';
import '../../domain/features/billing/usecases/update_payment_method_usecase.dart';
import '../../domain/features/billing/usecases/guardian_pay_usecase.dart';
import '../../presentation/features/billing/cubit/auto_pay_methods_cubit.dart';
import '../../presentation/features/billing/cubit/payment_settings_cubit.dart';
import '../../presentation/features/billing/cubit/pay_now_cubit.dart';
import '../../presentation/features/billing/cubit/pay_now_authorize_cubit.dart';
import '../../domain/features/billing/usecases/create_discount_usecase.dart';
import '../../domain/features/billing/usecases/update_discount_usecase.dart';
import '../../domain/features/billing/usecases/delete_discount_usecase.dart';
import '../../domain/features/billing/usecases/deactivate_discount_usecase.dart';
import '../../domain/features/billing/usecases/reactivate_discount_usecase.dart';
import '../../presentation/features/billing/cubit/analytics_cubit.dart';
import '../../presentation/features/billing/cubit/discount_cubit.dart';
import '../../presentation/features/billing/cubit/discount_form_cubit.dart';
import '../../domain/features/billing/usecases/get_guardian_family_ledger_usecase.dart';
import '../../domain/features/billing/usecases/get_invoice_analytics_usecase.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies({String? baseUrl}) async {
  if (serviceLocator.isRegistered<StorageService>()) {
    AppLogger.d(
      'configureDependencies called but StorageService is already registered. Skipping initialization.',
    );
    return;
  }
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Base URL
  final apiBaseUrl = baseUrl ?? ApiConstants.baseUrl;

  // Core
  serviceLocator.registerLazySingleton<Connectivity>(() => Connectivity());
  serviceLocator.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<SharedPreferences>(
    () => sharedPreferences,
  );
  serviceLocator.registerLazySingleton<StorageService>(
    () => StorageServiceImpl(serviceLocator()),
  );
  // Kiosk Access Control - must be registered early since other cubits depend on it
  serviceLocator.registerLazySingleton<KioskAccessControl>(
    () => KioskAccessControl(serviceLocator<StorageService>()),
  );
  // Biometric-gated secure store for the "Remember me" password (Keychain /
  // EncryptedSharedPreferences) — never the plaintext SharedPreferences.
  serviceLocator.registerLazySingleton<SecureCredentialStore>(
    () => SecureCredentialStore(),
  );

  // Cache
  final isarCacheService = IsarCacheService();
  await isarCacheService.init();
  serviceLocator.registerLazySingleton<CacheService>(() => isarCacheService);

  // Persistent, disk-backed cookie jar — the mobile equivalent of the web
  // clients' `credentials: 'include'`. The backend's refresh-token cookie
  // (set on /auth/login, read back on /auth/refresh) is captured and
  // re-attached here automatically; nothing in app code parses Set-Cookie
  // or constructs a Cookie header by hand. Stored under Application Support
  // (not Documents — this is app-internal state, not user-facing) so it
  // survives app restarts, not just hot reloads.
  final cookieDir = await getApplicationSupportDirectory();
  final cookieJar = PersistCookieJar(
    storage: FileStorage('${cookieDir.path}/.cookies/'),
  );
  serviceLocator.registerLazySingleton<CookieJar>(() => cookieJar);

  serviceLocator.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: apiBaseUrl,
      cookieJar: cookieJar,
      interceptors: <Interceptor>[
        AuthInterceptor(serviceLocator<StorageService>()),
      ],
      // Needs its own Dio so it can replay a request after a token refresh.
      interceptorsBuilder: (dio) => <Interceptor>[
        SessionExpiredInterceptor(dio),
      ],
    ),
  );
  serviceLocator.registerLazySingleton<ImageUploadService>(
    () => ImageUploadService(serviceLocator<ApiClient>()),
  );
  serviceLocator.registerLazySingleton<ProfilePhotoUploader>(
    () => ProfilePhotoUploader(serviceLocator<ImageUploadService>()),
  );

  // Auth Data Sources
  serviceLocator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Staff Data Sources
  serviceLocator.registerLazySingleton<StaffRemoteDataSource>(
    () => StaffRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Student Data Sources
  serviceLocator.registerLazySingleton<StudentRemoteDataSource>(
    () => StudentRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Attendance Data Sources
  serviceLocator.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<AvailabilityRemoteDataSource>(
    () => AvailabilityRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Staff Scheduling (staff MS — `/api/v1/staff-shifts`)
  serviceLocator.registerLazySingleton<StaffSchedulingRemoteDataSource>(
    () =>
        StaffSchedulingRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Classroom Data Sources
  serviceLocator.registerLazySingleton<ClassroomRemoteDataSource>(
    () => ClassroomRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Activity Data Sources
  serviceLocator.registerLazySingleton<ActivityRemoteDataSource>(
    () => ActivityRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Student-Classroom Data Sources
  serviceLocator.registerLazySingleton<StudentClassroomRemoteDataSource>(
    () => StudentClassroomRemoteDataSourceImpl(
      serviceLocator<ApiClient>().client,
      serviceLocator<StorageService>(),
    ),
  );

  // Staff-Classroom Data Sources
  serviceLocator.registerLazySingleton<StaffClassroomRemoteDataSource>(
    () =>
        StaffClassroomRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Staff Shift (scheduling)
  serviceLocator.registerLazySingleton<StaffShiftRemoteDataSource>(
    () => StaffShiftRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<CacheManager>(
    () => CacheManager(serviceLocator<StorageService>()),
  );
  serviceLocator.registerLazySingleton<StaffShiftRepository>(
    () => StaffShiftRepositoryImpl(
      serviceLocator<StaffShiftRemoteDataSource>(),
      serviceLocator<CacheManager>(),
    ),
  );

  // Onboarding Data Sources
  serviceLocator.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceMock(),
  );

  // Communication Data Sources
  serviceLocator.registerLazySingleton<CommunicationRemoteDataSource>(
    () => CommunicationRemoteDataSourceImpl(apiClient: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<NewsletterRemoteDataSource>(
    () => NewsletterRemoteDataSourceImpl(apiClient: serviceLocator()),
  );

  // Repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ClassroomRepository>(
    () => ClassroomRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
      serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<AvailabilityRepository>(
    () => AvailabilityRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StaffSchedulingRepository>(
    () => StaffSchedulingRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StudentClassroomRepository>(
    () => StudentClassroomRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StaffClassroomRepository>(
    () => StaffClassroomRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  // ===== COMMUNICATION V2.1 — REALTIME DATA SOURCES (Firestore) =====
  serviceLocator.registerLazySingleton<ConversationRealtimeDataSource>(
    () => FirebaseConversationRealtimeDataSource(
      firestore: FirebaseFirestore.instance,
    ),
  );

  serviceLocator.registerLazySingleton<MessageRealtimeDataSource>(
    () => FirebaseMessageRealtimeDataSource(
      firestore: FirebaseFirestore.instance,
    ),
  );

  serviceLocator.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepositoryImpl(
      remoteDataSource: serviceLocator(),
      cacheService: serviceLocator(),
      conversationRealtimeDataSource: serviceLocator(),
      messageRealtimeDataSource: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<ChatAttachmentUploader>(
    () => ChatAttachmentUploader(serviceLocator(), serviceLocator()),
  );

  serviceLocator.registerLazySingleton<FirebaseTokenDataSource>(
    () => FirebaseTokenDataSourceImpl(
      apiClient: serviceLocator(),
      messaging: FirebaseMessaging.instance,
      prefs: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthService(
      dio: serviceLocator<ApiClient>().client,
      storage: serviceLocator<StorageService>(),
    ),
  );

  // ===== COMMUNICATION V2.1 — DATA SOURCES (Phase 1B) =====
  serviceLocator.registerLazySingleton<ConversationEntityRemoteDataSource>(
    () => ConversationEntityRemoteDataSourceImpl(apiClient: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<ConversationEntityLocalDataSource>(
    () => ConversationEntityLocalDataSourceImpl(cacheService: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<MessageEntityRemoteDataSource>(
    () => MessageEntityRemoteDataSourceImpl(apiClient: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<MessageEntityLocalDataSource>(
    () => MessageEntityLocalDataSourceImpl(cacheService: serviceLocator()),
  );

  // ===== COMMUNICATION V2.1 — REPOSITORIES (Phase 1B) =====
  serviceLocator.registerLazySingleton<ConversationEntityRepository>(
    () => ConversationEntityRepositoryImpl(
      remoteDataSource: serviceLocator(),
      localDataSource: serviceLocator(),
      storageService: serviceLocator(),
      realtimeDataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<ReactionRepository>(
    () => ReactionRepositoryImpl(
      remoteDataSource: serviceLocator(),
      localDataSource: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<MessageEntityRepository>(
    () => MessageEntityRepositoryImpl(
      remoteDataSource: serviceLocator(),
      localDataSource: serviceLocator(),
      storageService: serviceLocator(),
      realtimeDataSource: serviceLocator(),
      reactionRepository: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<NewsletterRepository>(
    () => NewsletterRepositoryImpl(
      serviceLocator<NewsletterRemoteDataSource>(),
      serviceLocator<StorageService>(),
    ),
  );

  serviceLocator.registerLazySingleton<SessionLocalCacheWiper>(
    () => SessionLocalCacheWiper(
      cacheService: serviceLocator<CacheService>(),
      staffRepository: serviceLocator<StaffRepository>(),
    ),
  );
  serviceLocator.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      serviceLocator<StorageService>(),
      sessionLocalCacheWiper: serviceLocator<SessionLocalCacheWiper>(),
    ),
  );

  // Use cases
  serviceLocator.registerFactory<LoginUseCase>(
    () => LoginUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetOnboardingContent>(
    () => GetOnboardingContent(serviceLocator()),
  );
  serviceLocator.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerFactory<ProfileMenuHeaderCubit>(
    () => ProfileMenuHeaderCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<GetGuardianFamilyLedgerUseCase>(
    () => GetGuardianFamilyLedgerUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<ParentBillingCubit>(
    () => ParentBillingCubit(
      getGuardianFamilyLedger: serviceLocator<GetGuardianFamilyLedgerUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );

  // Reports - Data Layer
  serviceLocator.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(
      serviceLocator<ApiClient>().client,
      serviceLocator<StorageService>(),
    ),
  );

  // File Download Service
  serviceLocator.registerLazySingleton<FileDownloadService>(
    () => FileDownloadService(),
  );

  serviceLocator.registerLazySingleton<FileDownloadRepository>(
    () => FileDownloadRepository(serviceLocator<FileDownloadService>()),
  );

  serviceLocator.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(
      serviceLocator<ReportsRemoteDataSource>(),
      serviceLocator<StorageService>(),
    ),
  );

  // Reports - Domain Layer (Use Cases)
  serviceLocator.registerFactory<GenerateReportUseCase>(
    () => GenerateReportUseCase(serviceLocator()),
  );

  serviceLocator.registerFactory<GetRecentReportsUseCase>(
    () => GetRecentReportsUseCase(serviceLocator()),
  );

  serviceLocator.registerFactory<GetStudentTagsUseCase>(
    () => GetStudentTagsUseCase(serviceLocator()),
  );

  serviceLocator.registerFactory<DownloadReportUseCase>(
    () => DownloadReportUseCase(serviceLocator()),
  );

  // Reports - Presentation Layer (Cubit)
  serviceLocator.registerFactory<ReportsCubit>(
    () => ReportsCubit(
      storageService: serviceLocator(),
      getTagNameCodeMapForSchoolUseCase: serviceLocator(),
      generateReportUseCase: serviceLocator(),
      getRecentReportsUseCase: serviceLocator(),
      getStudentTagsUseCase: serviceLocator(),
      downloadReportUseCase: serviceLocator(),
      fileDownloadRepository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<EditUserProfileCubit>(
    () => EditUserProfileCubit(
      storageService: serviceLocator(),
      staffRepository: serviceLocator(),
      studentRemoteDataSource: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<UserProfileCubit>(
    () => UserProfileCubit(
      storageService: serviceLocator(),
      staffRepository: serviceLocator(),
      authRemoteDataSource: serviceLocator(),
      authLocalDataSource: serviceLocator(),
      studentRemoteDataSource: serviceLocator(),
      imageUploadService: serviceLocator(),
      getActiveClassroomsUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<GetStaffPageUseCase>(
    () => GetStaffPageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetAllStaffUseCase>(
    () => GetAllStaffUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffShiftsForDayUseCase>(
    () => GetStaffShiftsForDayUseCase(
      serviceLocator<StaffSchedulingRepository>(),
    ),
  );
  serviceLocator.registerFactory<GetStaffCountUseCase>(
    () => GetStaffCountUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddStaffDocumentUseCase>(
    () => AddStaffDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStaffDocumentUseCase>(
    () => UpdateStaffDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStaffDocumentUseCase>(
    () => DeleteStaffDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffDocumentsUseCase>(
    () => GetStaffDocumentsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffProfileUseCase>(
    () => GetStaffProfileUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetImportantDatesUseCase>(
    () => GetImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateImportantDatesUseCase>(
    () => UpdateImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateSchoolUserUseCase>(
    () => CreateSchoolUserUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetActiveClassroomsUseCase>(
    () => GetActiveClassroomsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetClassroomByCodeUseCase>(
    () => GetClassroomByCodeUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentPageUseCase>(
    () => GetStudentPageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<SelectStudentsCubit>(
    () => SelectStudentsCubit(
      getStudentPage: serviceLocator<GetStudentPageUseCase>(),
      getActiveClassrooms: serviceLocator<GetActiveClassroomsUseCase>(),
      getTagNameCodeMap: serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      checkRecipients: serviceLocator<CheckInvoiceRecipientsUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<GetStudentProfileUseCase>(
    () => GetStudentProfileUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceDailyUseCase>(
    () => GetStudentAttendanceDailyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetIndividualMovementsUseCase>(
    () => GetIndividualMovementsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetIndividualMovementByIdUseCase>(
    () => GetIndividualMovementByIdUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetFutureAvailabilityUseCase>(
    () => GetFutureAvailabilityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateIndividualMovementUseCase>(
    () => CreateIndividualMovementUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateIndividualMovementUseCase>(
    () => UpdateIndividualMovementUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteIndividualMovementUseCase>(
    () => DeleteIndividualMovementUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<TransitionIndividualMovementStatusUseCase>(
    () => TransitionIndividualMovementStatusUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceExpectedSummaryUseCase>(
    () => GetStudentAttendanceExpectedSummaryUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceCustomUseCase>(
    () => GetStudentAttendanceCustomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentSignInFormListUseCase>(
    () => GetStudentSignInFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentSignOutFormListUseCase>(
    () => GetStudentSignOutFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentTransferFormListUseCase>(
    () => GetStudentTransferFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAbsentFormListUseCase>(
    () => GetStudentAbsentFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAbsentRecordsActivityUseCase>(
    () => GetStudentAbsentRecordsActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceAbsentToggleViewUseCase>(
    () => GetStudentAttendanceAbsentToggleViewUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkStudentsAbsentUseCase>(
    () => MarkStudentsAbsentUseCase(serviceLocator()),
  );
  // Factories so each attendance form entry gets a fresh form state.
  serviceLocator.registerFactory<StudentMarkAbsentFormCubit>(
    () => StudentMarkAbsentFormCubit(
      markStudentsAbsentUseCase: serviceLocator(),
      storageService: serviceLocator(),
      apiClient: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentEditAttendanceFormCubit>(
    () => StudentEditAttendanceFormCubit(
      updateUseCase: serviceLocator(),
      storageService: serviceLocator(),
      apiClient: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffMarkAbsentFormCubit>(
    () => StaffMarkAbsentFormCubit(
      markStaffAbsentUseCase: serviceLocator(),
      storageService: serviceLocator(),
      apiClient: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffEditAttendanceFormCubit>(
    () => StaffEditAttendanceFormCubit(
      attendanceRepository: serviceLocator(),
      storageService: serviceLocator(),
      apiClient: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<GetStaffAttendanceDailyUseCase>(
    () => GetStaffAttendanceDailyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceExpectedSummaryUseCase>(
    () => GetStaffAttendanceExpectedSummaryUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceCustomUseCase>(
    () => GetStaffAttendanceCustomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceAbsentUseCase>(
    () => GetStaffAttendanceAbsentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceAbsentToggleViewUseCase>(
    () => GetStaffAttendanceAbsentToggleViewUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffSignInFormListUseCase>(
    () => GetStaffSignInFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffSignOutFormListUseCase>(
    () => GetStaffSignOutFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffTransferFormListUseCase>(
    () => GetStaffTransferFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAbsentFormListUseCase>(
    () => GetStaffAbsentFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkStaffAbsentUseCase>(
    () => MarkStaffAbsentUseCase(
      serviceLocator(),
      serviceLocator<StaffShiftRepository>(),
      serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<GetStaffTodaySignInStatusUseCase>(
    () => GetStaffTodaySignInStatusUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffTodaySignInStatusMapUseCase>(
    () => GetStaffTodaySignInStatusMapUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentTodaySignInStatusUseCase>(
    () => GetStudentTodaySignInStatusUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentTodaySignInStatusMapUseCase>(
    () => GetStudentTodaySignInStatusMapUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentAttendanceRecordUseCase>(
    () => UpdateStudentAttendanceRecordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<SubmitStudentSignInUseCase>(
    () => SubmitStudentSignInUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StudentSignInSubmitCubit>(
    () => StudentSignInSubmitCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<StudentSignInGateCubit>(
    () => StudentSignInGateCubit(
      getStudentSignInFormList: serviceLocator<GetStudentSignInFormListUseCase>(),
      storageService: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    ),
  );
  serviceLocator.registerFactory<StaffSignInGateCubit>(
    () => StaffSignInGateCubit(
      getStaffSignInFormList: serviceLocator<GetStaffSignInFormListUseCase>(),
      storageService: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    ),
  );
  serviceLocator.registerFactory<SubmitStudentSignOutUseCase>(
    () => SubmitStudentSignOutUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StudentSignOutSubmitCubit>(
    () => StudentSignOutSubmitCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<SubmitStudentTransferUseCase>(
    () => SubmitStudentTransferUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StudentTransferSubmitCubit>(
    () => StudentTransferSubmitCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<SubmitStaffSignInUseCase>(
    () => SubmitStaffSignInUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StaffSignInSubmitCubit>(
    () => StaffSignInSubmitCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<SubmitStaffSignOutUseCase>(
    () => SubmitStaffSignOutUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StaffSignOutSubmitCubit>(
    () => StaffSignOutSubmitCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<SubmitStaffTransferUseCase>(
    () => SubmitStaffTransferUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StaffTransferSubmitCubit>(
    () => StaffTransferSubmitCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStaffAttendanceRecordUseCase>(
    () => DeleteStaffAttendanceRecordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StaffAttendanceDeleteCubit>(
    () => StaffAttendanceDeleteCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStudentAttendanceRecordUseCase>(
    () => DeleteStudentAttendanceRecordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<StudentAttendanceDeleteCubit>(
    () => StudentAttendanceDeleteCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStudentAbsenceRecordUseCase>(
    () => DeleteStudentAbsenceRecordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStaffAbsenceRecordUseCase>(
    () => DeleteStaffAbsenceRecordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<FetchStudentAttendanceProfileUseCase>(
    () => FetchStudentAttendanceProfileUseCase(serviceLocator()),
  );
  serviceLocator
      .registerFactory<FetchStudentAttendanceProfileAbsentToggleUseCase>(
    () => FetchStudentAttendanceProfileAbsentToggleUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<FetchStaffAttendanceProfileUseCase>(
    () => FetchStaffAttendanceProfileUseCase(serviceLocator()),
  );
  serviceLocator
      .registerFactory<FetchStaffAttendanceProfileAbsentToggleUseCase>(
    () => FetchStaffAttendanceProfileAbsentToggleUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceAbsentViewUseCase>(
    () => GetStudentAttendanceAbsentViewUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentDocumentsUseCase>(
    () => GetStudentDocumentsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddStudentDocumentUseCase>(
    () => AddStudentDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentImportantDatesUseCase>(
    () => GetStudentImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentImportantDatesUseCase>(
    () => UpdateStudentImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentDocumentUseCase>(
    () => UpdateStudentDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStudentDocumentUseCase>(
    () => DeleteStudentDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentPhysiciansUseCase>(
    () => GetStudentPhysiciansUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddPhysicianUseCase>(
    () => AddPhysicianUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdatePhysicianUseCase>(
    () => UpdatePhysicianUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeletePhysicianUseCase>(
    () => DeletePhysicianUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentPickupsUseCase>(
    () => GetStudentPickupsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddPickupUseCase>(
    () => AddPickupUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdatePickupUseCase>(
    () => UpdatePickupUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeletePickupUseCase>(
    () => DeletePickupUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetGuardiansRawForSchoolUseCase>(
    () => GetGuardiansRawForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentGuardiansUseCase>(
    () => GetStudentGuardiansUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteGuardianUseCase>(
    () => DeleteGuardianUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentHealthUseCase>(
    () => GetStudentHealthUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentHealthUseCase>(
    () => UpdateStudentHealthUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentImmunizationsUseCase>(
    () => GetStudentImmunizationsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentImmunizationRecordUseCase>(
    () => UpdateStudentImmunizationRecordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentPhysicalExamsUseCase>(
    () => GetStudentPhysicalExamsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddStudentPhysicalExamUseCase>(
    () => AddStudentPhysicalExamUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentPhysicalExamUseCase>(
    () => UpdateStudentPhysicalExamUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetGuardianNamesForSchoolUseCase>(
    () => GetGuardianNamesForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetTagNamesForSchoolUseCase>(
    () => GetTagNamesForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetTagNameCodeMapForSchoolUseCase>(
    () => GetTagNameCodeMapForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentTagNamesUseCase>(
    () => GetStudentTagNamesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentTagsUseCase>(
    () => UpdateStudentTagsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentCodesForActivityTagFilterUseCase>(
    () => GetStudentCodesForActivityTagFilterUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetGuardianNameCodeMapForSchoolUseCase>(
    () => GetGuardianNameCodeMapForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetImmunizationSettingsUseCase>(
    () => GetImmunizationSettingsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetVaccineNameToCodeMapForSchoolUseCase>(
    () => GetVaccineNameToCodeMapForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentCountsUseCase>(
    () => GetStudentCountsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetSchoolCapacityUseCase>(
    () => GetSchoolCapacityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetRatioMonitoringClassroomsUseCase>(
    () => GetRatioMonitoringClassroomsUseCase(serviceLocator()),
  );
  serviceLocator
      .registerFactory<GetStudentAttendanceSummaryByClassroomsUseCase>(
        () => GetStudentAttendanceSummaryByClassroomsUseCase(serviceLocator()),
      );
  serviceLocator.registerFactory<GetStaffAttendanceSummaryByClassroomsUseCase>(
    () => GetStaffAttendanceSummaryByClassroomsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetClassroomCountUseCase>(
    () => GetClassroomCountUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetSchoolFteUseCase>(
    () => GetSchoolFteUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetClassroomActivitySettingsUseCase>(
    () => GetClassroomActivitySettingsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetActiveActivityTypesForSchoolUseCase>(
    () => GetActiveActivityTypesForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<ActivityFilterCubit>(
    () => ActivityFilterCubit(
      tagMapUseCase: serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      activityTypesUseCase:
          serviceLocator<GetActiveActivityTypesForSchoolUseCase>(),
      cacheManager: CacheManager(serviceLocator<StorageService>()),
    ),
  );
  serviceLocator.registerFactory<ActivityStudentSelectionCubit>(
    () => ActivityStudentSelectionCubit(
      storageService: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
      getActiveClassroomsUseCase: serviceLocator<GetActiveClassroomsUseCase>(),
      getTagNameCodeMapForSchoolUseCase:
          serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      getNapStartStudentsUseCase: serviceLocator<GetNapStartStudentsUseCase>(),
      staffRepository: serviceLocator<StaffRepository>(),
    ),
  );
  serviceLocator.registerFactory<StudentSignInSelectionCubit>(
    () => StudentSignInSelectionCubit(
      storageService: serviceLocator<StorageService>(),
      cacheManager: serviceLocator<CacheManager>(),
      getActiveClassroomsUseCase: serviceLocator<GetActiveClassroomsUseCase>(),
      getTagNameCodeMapForSchoolUseCase:
          serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      getStudentSignInFormListUseCase:
          serviceLocator<GetStudentSignInFormListUseCase>(),
    ),
  );
  serviceLocator.registerFactory<StudentSignOutSelectionCubit>(
    () => StudentSignOutSelectionCubit(
      storageService: serviceLocator<StorageService>(),
      cacheManager: serviceLocator<CacheManager>(),
      getActiveClassroomsUseCase: serviceLocator<GetActiveClassroomsUseCase>(),
      getTagNameCodeMapForSchoolUseCase:
          serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      getStudentSignOutFormListUseCase:
          serviceLocator<GetStudentSignOutFormListUseCase>(),
    ),
  );
  serviceLocator.registerFactory<StudentTransferSelectionCubit>(
    () => StudentTransferSelectionCubit(
      storageService: serviceLocator<StorageService>(),
      cacheManager: serviceLocator<CacheManager>(),
      getActiveClassroomsUseCase: serviceLocator<GetActiveClassroomsUseCase>(),
      getTagNameCodeMapForSchoolUseCase:
          serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      getStudentTransferFormListUseCase:
          serviceLocator<GetStudentTransferFormListUseCase>(),
    ),
  );
  serviceLocator.registerFactory<StudentMarkAbsentSelectionCubit>(
    () => StudentMarkAbsentSelectionCubit(
      storageService: serviceLocator<StorageService>(),
      cacheManager: serviceLocator<CacheManager>(),
      getActiveClassroomsUseCase: serviceLocator<GetActiveClassroomsUseCase>(),
      getTagNameCodeMapForSchoolUseCase:
          serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      getStudentAbsentFormListUseCase:
          serviceLocator<GetStudentAbsentFormListUseCase>(),
    ),
  );
  serviceLocator.registerFactory<ActivityModerationCubit>(
    () => ActivityModerationCubit(
      deleteActivityUseCase: serviceLocator<DeleteActivityUseCase>(),
      approveActivityUseCase: serviceLocator<ApproveActivityUseCase>(),
      rejectActivityUseCase: serviceLocator<RejectActivityUseCase>(),
    ),
  );
  serviceLocator.registerFactory<ActivityEditorCubit>(
    () => ActivityEditorCubit(
      getClassroomActivitySettingsUseCase:
          serviceLocator<GetClassroomActivitySettingsUseCase>(),
      getActivityTypeDetailsUseCase:
          serviceLocator<GetActivityTypeDetailsUseCase>(),
      createActivityUseCase: serviceLocator<CreateActivityUseCase>(),
      getActivityUseCase: serviceLocator<GetActivityUseCase>(),
      updateActivityUseCase: serviceLocator<UpdateActivityUseCase>(),
      approveActivityUseCase: serviceLocator<ApproveActivityUseCase>(),
      rejectActivityUseCase: serviceLocator<RejectActivityUseCase>(),
      createSharedActivitiesUseCase:
          serviceLocator<CreateSharedActivitiesUseCase>(),
      guardianParentSignatureUseCase:
          serviceLocator<GuardianParentSignatureUseCase>(),
      getGuardianNameCodeMapForSchoolUseCase:
          serviceLocator<GetGuardianNameCodeMapForSchoolUseCase>(),
      getStaffTodaySignInStatusUseCase:
          serviceLocator<GetStaffTodaySignInStatusUseCase>(),
    ),
  );
  // Per-form ViewModel for the Medication activity screen. Factory so each
  // screen entry gets fresh form state; it owns its own ActivityEditorCubit.
  serviceLocator.registerFactory<MedicationActivityCubit>(
    () => MedicationActivityCubit(
      editor: serviceLocator<ActivityEditorCubit>(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<BottleActivityCubit>(
    () => BottleActivityCubit(
      editor: serviceLocator<ActivityEditorCubit>(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<NapActivityCubit>(
    () => NapActivityCubit(
      getNapStartStudentsUseCase: serviceLocator<GetNapStartStudentsUseCase>(),
    ),
  );
  serviceLocator.registerFactory<IncidentActivityCubit>(
    () => IncidentActivityCubit(
      storageService: serviceLocator<StorageService>(),
      staffRepository: serviceLocator<StaffRepository>(),
    ),
  );
  serviceLocator.registerFactory<ActivityFeedScopeCubit>(
    () => ActivityFeedScopeCubit(
      getDailyActivityFeedUseCase: serviceLocator<GetDailyActivityFeedUseCase>(),
      getRangeActivityFeedUseCase: serviceLocator<GetRangeActivityFeedUseCase>(),
      getActiveClassroomsUseCase: serviceLocator<GetActiveClassroomsUseCase>(),
      getActiveActivityTypesForSchoolUseCase:
          serviceLocator<GetActiveActivityTypesForSchoolUseCase>(),
      getStudentClassroomListUseCase:
          serviceLocator<GetStudentClassroomListUseCase>(),
      getTagNameCodeMapForSchoolUseCase:
          serviceLocator<GetTagNameCodeMapForSchoolUseCase>(),
      getStudentCodesForActivityTagFilterUseCase:
          serviceLocator<GetStudentCodesForActivityTagFilterUseCase>(),
      getStudentPageUseCase: serviceLocator<GetStudentPageUseCase>(),
      getStudentAttendanceDailyUseCase:
          serviceLocator<GetStudentAttendanceDailyUseCase>(),
      getStudentAbsentRecordsActivityUseCase:
          serviceLocator<GetStudentAbsentRecordsActivityUseCase>(),
      staffRepository: serviceLocator<StaffRepository>(),
      storageService: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<GetActivityTypeDetailsUseCase>(
    () => GetActivityTypeDetailsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateActivityUseCase>(
    () => CreateActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateSharedActivitiesUseCase>(
    () => CreateSharedActivitiesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetActivityUseCase>(
    () => GetActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateActivityUseCase>(
    () => UpdateActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteActivityUseCase>(
    () => DeleteActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<ApproveActivityUseCase>(
    () => ApproveActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<RejectActivityUseCase>(
    () => RejectActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AcknowledgeActivityUseCase>(
    () => AcknowledgeActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GuardianParentSignatureUseCase>(
    () => GuardianParentSignatureUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateActivityUploadSessionsUseCase>(
    () => CreateActivityUploadSessionsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateActivityAssetPresignUseCase>(
    () => CreateActivityAssetPresignUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetDailyActivityFeedUseCase>(
    () => GetDailyActivityFeedUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetRangeActivityFeedUseCase>(
    () => GetRangeActivityFeedUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetNapStartStudentsUseCase>(
    () => GetNapStartStudentsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentClassroomListUseCase>(
    () => GetStudentClassroomListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AssignStudentsToClassroomUseCase>(
    () => AssignStudentsToClassroomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffClassroomsUseCase>(
    () => GetStaffClassroomsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AssignStaffToClassroomUseCase>(
    () => AssignStaffToClassroomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetMessagesUseCase>(
    () => GetMessagesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<SendMessageUseCase>(
    () => SendMessageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateConversationUseCase>(
    () => CreateConversationUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetConversationsUseCase>(
    () => GetConversationsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetCachedConversationsUseCase>(
    () => GetCachedConversationsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetCachedMessagesUseCase>(
    () => GetCachedMessagesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CacheMessageUseCase>(
    () => CacheMessageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DiscardCachedMessageUseCase>(
    () => DiscardCachedMessageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddReactionUseCase>(
    () => AddReactionUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<EditMessageUseCase>(
    () => EditMessageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteMessageUseCase>(
    () => DeleteMessageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteAttachmentUseCase>(
    () => DeleteAttachmentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<RemoveReactionLegacyUseCase>(
    () => RemoveReactionLegacyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<ClearMessagesCacheUseCase>(
    () => ClearMessagesCacheUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<ClearConversationsCacheUseCase>(
    () => ClearConversationsCacheUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<WatchMessagesLegacyUseCase>(
    () => WatchMessagesLegacyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<WatchConversationsLegacyUseCase>(
    () => WatchConversationsLegacyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkConversationDeliveredUseCase>(
    () => MarkConversationDeliveredUseCase(serviceLocator()),
  );

  // ===== COMMUNICATION V2.1 — USE CASES (Phase 1C) =====
  // ConversationEntityRepository use cases
  serviceLocator.registerFactory<GetConversationsEntityUseCase>(
    () => GetConversationsEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetConversationEntityUseCase>(
    () => GetConversationEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetCachedConversationsEntityUseCase>(
    () => GetCachedConversationsEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateConversationEntityUseCase>(
    () => CreateConversationEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateOrOpenConversationUseCase>(
    () => CreateOrOpenConversationUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetConversationsForStudentUseCase>(
    () => GetConversationsForStudentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetConversationsForClassroomUseCase>(
    () => GetConversationsForClassroomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetOrCreateClassroomChatUseCase>(
    () => GetOrCreateClassroomChatUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetClassroomRosterPresentUserCodesUseCase>(
    () => GetClassroomRosterPresentUserCodesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<TogglePrivateModeUseCase>(
    () => TogglePrivateModeUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkConversationReadUseCase>(
    () => MarkConversationReadUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetUnreadCountsPerConversationUseCase>(
    () => GetUnreadCountsPerConversationUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetMessageReceiptsUseCase>(
    () => GetMessageReceiptsUseCase(serviceLocator()),
  );
  // Single app-session instance — previously each consumer (GlobalScaffold,
  // StaffAttendanceTabbedView, StudentAttendanceTabbedView) constructed its
  // own UnreadBadgeCubit, opening up to 3x the Firestore listeners for the
  // same data whenever more than one was mounted at once.
  serviceLocator.registerLazySingleton<UnreadBadgeCubit>(
    () => UnreadBadgeCubit(
      watchUnreadCountForTypeUseCase: serviceLocator(),
      watchTotalUnreadCountUseCase: serviceLocator(),
    ),
  );
  // MessageEntityRepository use cases
  serviceLocator.registerFactory<GetMessagesEntityUseCase>(
    () => GetMessagesEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<SendMessageEntityUseCase>(
    () => SendMessageEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CacheDraftMessageUseCase>(
    () => CacheDraftMessageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkDraftMessageFailedUseCase>(
    () => MarkDraftMessageFailedUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetCachedMessagesEntityUseCase>(
    () => GetCachedMessagesEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<EditMessageEntityUseCase>(
    () => EditMessageEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteMessageEntityUseCase>(
    () => DeleteMessageEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteAttachmentEntityUseCase>(
    () => DeleteAttachmentEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetMessageEntityReceiptsUseCase>(
    () => GetMessageEntityReceiptsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<SearchMessagesUseCase>(
    () => SearchMessagesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddReactionEntityUseCase>(
    () => AddReactionEntityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<RemoveReactionUseCase>(
    () => RemoveReactionUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<SyncPendingOperationsUseCase>(
    () => SyncPendingOperationsUseCase(serviceLocator()),
  );
  // Realtime (Firestore) use cases
  serviceLocator.registerFactory<WatchConversationsUseCase>(
    () => WatchConversationsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<WatchTotalUnreadCountUseCase>(
    () => WatchTotalUnreadCountUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<WatchMessagesUseCase>(
    () => WatchMessagesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<WatchUnreadCountForTypeUseCase>(
    () => WatchUnreadCountForTypeUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<RegisterFirebaseTokenUseCase>(
    () => RegisterFirebaseTokenUseCase(serviceLocator()),
  );

  serviceLocator.registerFactory<GetStaffShiftsUseCase>(
    () => GetStaffShiftsUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<CreateStaffShiftUseCase>(
    () => CreateStaffShiftUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<UpdateStaffShiftUseCase>(
    () => UpdateStaffShiftUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<UpdateStaffShiftSeriesUseCase>(
    () => UpdateStaffShiftSeriesUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<DeleteStaffShiftUseCase>(
    () => DeleteStaffShiftUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<DeleteStaffShiftSeriesUseCase>(
    () => DeleteStaffShiftSeriesUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetStaffShiftByCodeUseCase>(
    () => GetStaffShiftByCodeUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetSchoolStaffShiftsUseCase>(
    () => GetSchoolStaffShiftsUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetClassroomForecastUseCase>(
    () => GetClassroomForecastUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetClassroomForecastRangeUseCase>(
    () => GetClassroomForecastRangeUseCase(
      serviceLocator<StaffShiftRepository>(),
    ),
  );
  serviceLocator.registerFactory<GetStaffShiftHoursRangeUseCase>(
    () =>
        GetStaffShiftHoursRangeUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<PublishStaffShiftsUseCase>(
    () => PublishStaffShiftsUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetSentNewslettersUseCase>(
    () => GetSentNewslettersUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetNewsletterByCodeUseCase>(
    () => GetNewsletterByCodeUseCase(serviceLocator()),
  );

  // Cubits (factory - new instance each time for UI)
  serviceLocator.registerFactory<ClassroomShiftsCubit>(
    () => ClassroomShiftsCubit(
      getActiveClassroomsUseCase: serviceLocator(),
      getClassroomForecastUseCase: serviceLocator(),
      getSchoolStaffShiftsUseCase: serviceLocator(),
      staffRepository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<MyAttendanceCubit>(
    () => MyAttendanceCubit(
      attendanceRepository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<MyShiftsCubit>(
    () => MyShiftsCubit(
      getStaffShiftsUseCase: serviceLocator(),
      getClassroomsUseCase: serviceLocator(),
      storageService: serviceLocator(),
      staffRepository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<AdminDashboardCubit>(
    () => AdminDashboardCubit(),
  );
  serviceLocator.registerFactory<StaffDashboardCubit>(
    () => StaffDashboardCubit(),
  );
  serviceLocator.registerFactory<ParentDashboardCubit>(
    () => ParentDashboardCubit(),
  );

  serviceLocator.registerLazySingleton<ParentChildCubit>(
    () => ParentChildCubit(),
  );

  // Dashboard Coordinators & Factory
  serviceLocator.registerLazySingleton<DashboardCubitFactory>(
    () => DashboardCubitFactory(serviceLocator),
  );
  serviceLocator.registerFactory<ParentDashboardCoordinatorCubit>(
    () => serviceLocator<DashboardCubitFactory>()
        .createParentDashboardCoordinator(),
  );
  serviceLocator.registerFactory<StaffDashboardCoordinatorCubit>(
    () => serviceLocator<DashboardCubitFactory>()
        .createStaffDashboardCoordinator(),
  );
  serviceLocator.registerFactory<AdminDashboardCoordinatorCubit>(
    () => serviceLocator<DashboardCubitFactory>()
        .createAdminDashboardCoordinator(),
  );
  serviceLocator.registerFactory<MyDayCubit>(
    () => MyDayCubit(
      staffRepository: serviceLocator(),
      storageService: serviceLocator(),
      apiClient: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<WorkBreakReminderCubit>(
    () => WorkBreakReminderCubit(staffRepository: serviceLocator()),
  );
  serviceLocator.registerFactory<DashboardAttentionCubit>(
    () => DashboardAttentionCubit(
      activityRepository: serviceLocator(),
      availabilityRepository: serviceLocator(),
      staffRepository: serviceLocator(),
      studentRepository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<RatioMonitoringCubit>(
    () => RatioMonitoringCubit(
      getRatioMonitoringClassroomsUseCase: serviceLocator(),
      getStudentAttendanceSummaryByClassroomsUseCase: serviceLocator(),
      getStaffAttendanceSummaryByClassroomsUseCase: serviceLocator(),
      cacheManager: serviceLocator(),
      storageService: serviceLocator(),
      getStaffShiftsUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<SchoolStatusCubit>(
    () => SchoolStatusCubit(
      getStudentCountsUseCase: serviceLocator(),
      getSchoolCapacityUseCase: serviceLocator(),
      getClassroomCountUseCase: serviceLocator(),
      getSchoolFteUseCase: serviceLocator(),
      getStaffAttendanceExpectedSummaryUseCase: serviceLocator(),
      getStudentAttendanceExpectedSummaryUseCase: serviceLocator(),
      cacheManager: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<AuthCubit>(
    () => AuthCubit(
      loginUseCase: serviceLocator(),
      localDataSource: serviceLocator(),
      remoteDataSource: serviceLocator(),
      registerDeviceFcmToken: serviceLocator(),
      unregisterDeviceFcmToken: serviceLocator(),
      firebaseAuthService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffCubit>(
    () => StaffCubit(
      getStaffPageUseCase: serviceLocator(),
      getStaffCountUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffDocumentCubit>(
    () => StaffDocumentCubit(
      addStaffDocumentUseCase: serviceLocator(),
      updateStaffDocumentUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffDocumentsListCubit>(
    () => StaffDocumentsListCubit(
      getStaffDocumentsUseCase: serviceLocator(),
      deleteStaffDocumentUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffProfileCubit>(
    () => StaffProfileCubit(
      getStaffProfileUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ImportantDatesCubit>(
    () => ImportantDatesCubit(updateImportantDatesUseCase: serviceLocator()),
  );
  serviceLocator.registerFactory<CreateSchoolUserCubit>(
    () => CreateSchoolUserCubit(
      createSchoolUserUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ClassroomCubit>(
    () => ClassroomCubit(
      getActiveClassroomsUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ClassroomStudentsCubit>(
    () => ClassroomStudentsCubit(
      getStudentClassroomListUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ClassroomStaffCubit>(
    () => ClassroomStaffCubit(
      getStaffClassroomsUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentCubit>(
    () => StudentCubit(
      getStudentPageUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory<MyChildsDayCubit>(
    () => MyChildsDayCubit(
      getStudentProfileUseCase: serviceLocator(),
      storageService: serviceLocator(),
      apiClient: serviceLocator(),
      studentRepository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentAttendanceProfileCubit>(
    () => StudentAttendanceProfileCubit(
      getStudentAttendanceCustomUseCase: serviceLocator(),
      getStudentAttendanceAbsentToggleViewUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentNewslettersCubit>(
    () =>
        StudentNewslettersCubit(getStudentNewslettersUseCase: serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ValidateQrCodeUseCase>(
    () => ValidateQrCodeUseCase(serviceLocator<AttendanceRepository>()),
  );
  serviceLocator.registerFactory<QrValidationCubit>(
    () => QrValidationCubit(
      validateQrCodeUseCase: serviceLocator(),
      getStaffTodaySignInStatusUseCase: serviceLocator(),
      getStudentTodaySignInStatusMapUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory<StudentAttendanceDailyCubit>(
    () => StudentAttendanceDailyCubit(
      getStudentAttendanceDailyUseCase: serviceLocator(),
      getStudentAttendanceExpectedSummaryUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<IndividualMovementsCubit>(
    () => IndividualMovementsCubit(
      createIndividualMovementUseCase: serviceLocator(),
      updateIndividualMovementUseCase: serviceLocator(),
      deleteIndividualMovementUseCase: serviceLocator(),
      getIndividualMovementByIdUseCase: serviceLocator(),
      getIndividualMovementsUseCase: serviceLocator(),
      transitionIndividualMovementStatusUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<FutureAvailabilityCubit>(
    () => FutureAvailabilityCubit(
      getFutureAvailabilityUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentAttendanceAbsentToggleCubit>(
    () => StudentAttendanceAbsentToggleCubit(
      getStudentAttendanceAbsentToggleViewUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentAttendanceCustomCubit>(
    () => StudentAttendanceCustomCubit(
      getStudentAttendanceCustomUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceDailyCubit>(
    () => StaffAttendanceDailyCubit(
      getStaffAttendanceDailyUseCase: serviceLocator(),
      getStaffAttendanceExpectedSummaryUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceCustomCubit>(
    () => StaffAttendanceCustomCubit(
      getStaffAttendanceCustomUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceAbsentCubit>(
    () => StaffAttendanceAbsentCubit(
      getStaffAttendanceAbsentUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceAbsentToggleCubit>(
    () => StaffAttendanceAbsentToggleCubit(
      getStaffAttendanceAbsentToggleViewUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentDocumentsListCubit>(
    () => StudentDocumentsListCubit(
      getStudentDocumentsUseCase: serviceLocator(),
      deleteStudentDocumentUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentPhysicianCubit>(
    () => StudentPhysicianCubit(
      getStudentPhysiciansUseCase: serviceLocator(),
      addPhysicianUseCase: serviceLocator(),
      updatePhysicianUseCase: serviceLocator(),
      deletePhysicianUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentTagsCubit>(
    () => StudentTagsCubit(
      getStudentTagNamesUseCase: serviceLocator(),
      getTagNamesForSchoolUseCase: serviceLocator(),
      getTagNameCodeMapForSchoolUseCase: serviceLocator(),
      updateStudentTagsUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentPickupCubit>(
    () => StudentPickupCubit(
      getStudentPickupsUseCase: serviceLocator(),
      getGuardiansRawForSchoolUseCase: serviceLocator(),
      addPickupUseCase: serviceLocator(),
      updatePickupUseCase: serviceLocator(),
      deletePickupUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentGuardianCubit>(
    () => StudentGuardianCubit(
      getStudentGuardiansUseCase: serviceLocator(),
      deleteGuardianUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentHealthCubit>(
    () => StudentHealthCubit(
      getStudentHealthUseCase: serviceLocator(),
      updateStudentHealthUseCase: serviceLocator(),
      getStudentImmunizationsUseCase: serviceLocator(),
      updateStudentImmunizationRecordUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentPhysicalExamCubit>(
    () => StudentPhysicalExamCubit(
      getStudentPhysicalExamsUseCase: serviceLocator(),
      addStudentPhysicalExamUseCase: serviceLocator(),
      updateStudentPhysicalExamUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentDocumentCubit>(
    () => StudentDocumentCubit(
      addStudentDocumentUseCase: serviceLocator(),
      updateStudentDocumentUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentImportantDatesCubit>(
    () => StudentImportantDatesCubit(
      updateStudentImportantDatesUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<CommunicationCubit>(
    () => CommunicationCubit(
      getMessagesUseCase: serviceLocator<GetMessagesUseCase>(),
      sendMessageUseCase: serviceLocator<SendMessageUseCase>(),
      getConversationsUseCase: serviceLocator<GetConversationsUseCase>(),
      getCachedConversationsUseCase:
          serviceLocator<GetCachedConversationsUseCase>(),
      getCachedMessagesUseCase: serviceLocator<GetCachedMessagesUseCase>(),
      addReactionUseCase: serviceLocator<AddReactionUseCase>(),
      editMessageUseCase: serviceLocator<EditMessageUseCase>(),
      deleteMessageUseCase: serviceLocator<DeleteMessageUseCase>(),
      deleteAttachmentUseCase: serviceLocator<DeleteAttachmentUseCase>(),
      removeReactionLegacyUseCase:
          serviceLocator<RemoveReactionLegacyUseCase>(),
      clearMessagesCacheUseCase: serviceLocator<ClearMessagesCacheUseCase>(),
      clearConversationsCacheUseCase:
          serviceLocator<ClearConversationsCacheUseCase>(),
      attachmentUploader: serviceLocator<ChatAttachmentUploader>(),
      watchMessagesUseCase: serviceLocator<WatchMessagesLegacyUseCase>(),
      watchConversationsUseCase:
          serviceLocator<WatchConversationsLegacyUseCase>(),
      markConversationDeliveredUseCase:
          serviceLocator<MarkConversationDeliveredUseCase>(),
      markConversationReadUseCase:
          serviceLocator<MarkConversationReadUseCase>(),
      storageService: serviceLocator<StorageService>(),
      cacheMessageUseCase: serviceLocator<CacheMessageUseCase>(),
      discardCachedMessageUseCase:
          serviceLocator<DiscardCachedMessageUseCase>(),
      getMessageReceiptsUseCase: serviceLocator<GetMessageReceiptsUseCase>(),
    ),
  );

  serviceLocator.registerLazySingleton<StudentNewslettersRemoteDataSource>(
    () => StudentNewslettersRemoteDataSourceImpl(apiClient: serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StudentNewslettersRepository>(
    () => StudentNewslettersRepositoryImpl(remoteDataSource: serviceLocator()),
  );
  serviceLocator.registerLazySingleton<GetStudentNewslettersUseCase>(
    () => GetStudentNewslettersUseCase(serviceLocator()),
  );
  // Singleton so the scheduling staff list is loaded once per session and
  // shared between [StaffSchedulingCubit] (injected via DI) and the widget
  // tree (provided via `BlocProvider.value`). Lets AddShift reuse the cached
  // staff list instead of triggering a second fetch.
  serviceLocator.registerLazySingleton<SchedulingStaffListCubit>(
    () => SchedulingStaffListCubit(
      getAllStaffUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  // Singleton so state survives across screen entries — entering the route
  // a second time uses cached classrooms/shifts/staff and refreshes silently
  // in the background instead of flashing the full-page shimmer.
  serviceLocator.registerLazySingleton<StaffSchedulingCubit>(
    () => StaffSchedulingCubit(
      schedulingStaffListCubit: serviceLocator(),
      getSchoolStaffShiftsUseCase:
          serviceLocator<GetSchoolStaffShiftsUseCase>(),
      getStaffShiftHoursRangeUseCase:
          serviceLocator<GetStaffShiftHoursRangeUseCase>(),
      getActiveClassroomsUseCase: serviceLocator(),
      staffRepository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<PublishShiftsCubit>(
    () => PublishShiftsCubit(
      publishStaffShiftsUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  // Factory so each Add Shift screen entry gets a fresh form state.
  serviceLocator.registerFactory<AddShiftCubit>(
    () => AddShiftCubit(
      getActiveClassroomsUseCase: serviceLocator(),
      staffRepository: serviceLocator(),
      staffShiftRepository: serviceLocator(),
      getStaffShiftsUseCase: serviceLocator(),
      createStaffShiftUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  // Factory so each Edit Shift screen entry gets a fresh form state.
  serviceLocator.registerFactory<EditShiftCubit>(
    () => EditShiftCubit(
      getActiveClassroomsUseCase: serviceLocator(),
      staffRepository: serviceLocator(),
      staffShiftRepository: serviceLocator(),
      getStaffShiftsUseCase: serviceLocator(),
      updateStaffShiftUseCase: serviceLocator(),
      updateStaffShiftSeriesUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<SchedulingCubit>(
    () => SchedulingCubit(
      getSchoolStaffShiftsUseCase: serviceLocator(),
      getClassroomForecastUseCase: serviceLocator(),
      getClassroomForecastRangeUseCase: serviceLocator(),
      getStaffShiftHoursRangeUseCase: serviceLocator(),
      schedulingStaffListCubit: serviceLocator(),
      staffRepository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<NewsletterListCubit>(
    () => NewsletterListCubit(
      getSentNewslettersUseCase: serviceLocator(),
      repository: serviceLocator<NewsletterRepository>(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<PreviewNewsletterCubit>(
    () => PreviewNewsletterCubit(serviceLocator()),
  );

  // Geofencing Feature
  serviceLocator.registerLazySingleton<GeofencingLocalDataSource>(
    () => GeofencingLocalDataSourceImpl(),
  );
  serviceLocator.registerLazySingleton<GeofencingRepository>(
    () => GeofencingRepositoryImpl(
      localDataSource: serviceLocator(),
      apiClient: serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<GeofenceNotificationService>(
    () => GeofenceNotificationService(),
  );

  // Push notifications (FCM) — domain → data → presentation.
  serviceLocator.registerLazySingleton<FirebaseMessaging>(
    () => FirebaseMessaging.instance,
  );
  serviceLocator.registerLazySingleton<FcmRemoteDataSource>(
    () => FcmRemoteDataSourceImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<FcmRegistrationRemoteDataSource>(
    () => FcmRegistrationRemoteDataSourceImpl(apiClient: serviceLocator()),
  );
  serviceLocator.registerLazySingleton<FcmTokenRegistrationService>(
    () => FcmTokenRegistrationService(
      remote: serviceLocator(),
      storage: serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<FcmRegistrationRepository>(
    () => FcmRegistrationRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerFactory<RegisterDeviceFcmTokenUseCase>(
    () => RegisterDeviceFcmTokenUseCase(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerFactory<UnregisterDeviceFcmTokenUseCase>(
    () => UnregisterDeviceFcmTokenUseCase(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<PushNotificationRepository>(
    () => PushNotificationRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerFactory<PushNotificationCubit>(
    () => PushNotificationCubit(
      repository: serviceLocator(),
      localNotifications: serviceLocator(),
      registerDeviceFcmToken: serviceLocator(),
    ),
  );

  // Notification center (bell-icon inbox) — /notification/inbox API.
  serviceLocator.registerLazySingleton<NotificationInboxRemoteDataSource>(
    () => NotificationInboxRemoteDataSourceImpl(apiClient: serviceLocator()),
  );
  serviceLocator.registerLazySingleton<NotificationCenterDataSource>(
    () => NotificationCenterRemoteDataSource(
      inboxRemote: serviceLocator(),
      storage: serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<NotificationCenterRepository>(
    () => NotificationCenterRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerFactory<GetNotificationsUseCase>(
    () => GetNotificationsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkNotificationReadUseCase>(
    () => MarkNotificationReadUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkAllNotificationsReadUseCase>(
    () => MarkAllNotificationsReadUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetNotificationUnreadCountsUseCase>(
    () => GetNotificationUnreadCountsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<NotificationCenterCubit>(
    () => NotificationCenterCubit(
      getNotificationsUseCase: serviceLocator(),
      markNotificationReadUseCase: serviceLocator(),
      markAllNotificationsReadUseCase: serviceLocator(),
      getUnreadCountsUseCase: serviceLocator(),
    ),
  );
  // Sole source for the bell badge count: a Firestore listener on
  // userNotifications/{userCode}/notifications, counted client-side per
  // snapshot — never REST (see NotificationRealtimeDataSource's own doc).
  serviceLocator.registerLazySingleton<NotificationRealtimeDataSource>(
    () => FirebaseNotificationRealtimeDataSource(
      firestore: FirebaseFirestore.instance,
    ),
  );
  // Shared app-session singleton powering the app-bar bell badge (mirrors
  // UnreadBadgeCubit). Provided at the app root; started on GlobalScaffold mount.
  serviceLocator.registerLazySingleton<NotificationBadgeCubit>(
    () => NotificationBadgeCubit(
      realtime: serviceLocator<NotificationRealtimeDataSource>(),
      storage: serviceLocator<StorageService>(),
    ),
  );

  // Notification preferences (settings screen) — GET/PATCH /preferences/groups.
  serviceLocator
      .registerLazySingleton<NotificationPreferenceGroupsRemoteDataSource>(
        () => NotificationPreferenceGroupsRemoteDataSourceImpl(
          serviceLocator<ApiClient>().client,
        ),
      );
  serviceLocator.registerLazySingleton<NotificationPreferenceGroupsRepository>(
    () => NotificationPreferenceGroupsRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerFactory<GetNotificationPreferenceGroupsUseCase>(
    () => GetNotificationPreferenceGroupsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateNotificationPreferenceGroupsUseCase>(
    () => UpdateNotificationPreferenceGroupsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<NotificationPreferenceGroupsCubit>(
    () => NotificationPreferenceGroupsCubit(
      getGroups: serviceLocator(),
      updateGroups: serviceLocator(),
      storage: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<CheckLocationPermissionUseCase>(
    () => CheckLocationPermissionUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<RequestLocationPermissionUseCase>(
    () => RequestLocationPermissionUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetSchoolLocationUseCase>(
    () => GetSchoolLocationUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<WatchGeofenceUseCase>(
    () => WatchGeofenceUseCase(serviceLocator()),
  );
  // Singleton — one cubit for the entire app lifetime so GPS state survives
  // navigation. Never call close() on this from a dashboard widget.
  serviceLocator.registerLazySingleton<GeofenceCubit>(
    () => GeofenceCubit(
      checkLocationPermissionUseCase: serviceLocator(),
      requestLocationPermissionUseCase: serviceLocator(),
      getSchoolLocationUseCase: serviceLocator(),
      watchGeofenceUseCase: serviceLocator(),
      notificationService: serviceLocator(),
    ),
  );

  // Initialize notification service after registering it
  // Wrap in try-catch in case native plugin isn't ready yet
  try {
    await serviceLocator<GeofenceNotificationService>().init();
  } catch (e) {
    // Native plugin might not be loaded yet - will retry when geofence cubit initializes
    AppLogger.d('Warning: Notification service initialization deferred: $e');
  }

  // ===== KIOSK FEATURE =====
  // Data layer
  serviceLocator.registerLazySingleton<KioskRemoteDataSource>(
    () => KioskRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<KioskRepository>(
    () => KioskRepositoryImpl(serviceLocator()),
  );

  // === REFACTORED KIOSK MODULE - CLEAN ARCHITECTURE ===

  // Data layer - Remote datasources
  serviceLocator.registerSingleton<KioskAttendanceRemoteDataSource>(
    KioskAttendanceRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Data layer - Repository implementations
  serviceLocator.registerSingleton<KioskAttendanceRepository>(
    KioskAttendanceRepositoryImpl(
      serviceLocator<KioskAttendanceRemoteDataSource>(),
    ),
  );

  // Domain layer - Use cases
  serviceLocator.registerFactory<SignInStaffUseCase>(
    () => SignInStaffUseCase(serviceLocator<KioskAttendanceRepository>()),
  );
  serviceLocator.registerFactory<SignOutStaffUseCase>(
    () => SignOutStaffUseCase(serviceLocator<KioskAttendanceRepository>()),
  );

  // Legacy domain layer (still used for kiosk QR and PIN)
  serviceLocator.registerFactory<GetActiveKioskQrUseCase>(
    () => GetActiveKioskQrUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<VerifyKioskPinUseCase>(
    () => VerifyKioskPinUseCase(serviceLocator()),
  );

  // Presentation layer - Cubits
  serviceLocator.registerFactory<KioskDashboardCubit>(
    () => KioskDashboardCubit(
      getActiveKioskQrUseCase: serviceLocator(),
      verifyKioskPinUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );

  // REFACTORED: KioskAttendanceCubitV2 using Clean Architecture
  serviceLocator.registerFactory<KioskAttendanceCubitV2>(
    () => KioskAttendanceCubitV2(
      signInStaffUseCase: serviceLocator<SignInStaffUseCase>(),
      signOutStaffUseCase: serviceLocator<SignOutStaffUseCase>(),
      storageService: serviceLocator(),
      apiClient: serviceLocator(),
    ),
  );

  // Kiosk logout cubit
  serviceLocator.registerFactory<KioskLogoutCubit>(
    () => KioskLogoutCubit(
      authCubit: serviceLocator<AuthCubit>(),
      verifyKioskPinUseCase: serviceLocator<VerifyKioskPinUseCase>(),
      storageService: serviceLocator<StorageService>(),
      kioskAccessControl: serviceLocator<KioskAccessControl>(),
    ),
  );

  // Legacy cubit (kept for backwards compatibility if needed)
  // serviceLocator.registerFactory<KioskAttendanceCubit>(
  //   () => KioskAttendanceCubit(
  //     attendanceRepository: serviceLocator(),
  //     storageService: serviceLocator(),
  //     apiClient: serviceLocator(),
  //   ),
  // );

  // ── Billing ───────────────────────────────────────────────────────────────
  serviceLocator.registerLazySingleton<LedgerRemoteDataSource>(
    () => LedgerRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<LedgerRepository>(
    () => LedgerRepositoryImpl(serviceLocator<LedgerRemoteDataSource>()),
  );
  serviceLocator.registerLazySingleton<LedgerTransactionRemoteDataSource>(
    () => LedgerTransactionRemoteDataSourceImpl(
      serviceLocator<ApiClient>().client,
    ),
  );
  serviceLocator.registerLazySingleton<LedgerTransactionRepository>(
    () => LedgerTransactionRepositoryImpl(
      serviceLocator<LedgerTransactionRemoteDataSource>(),
    ),
  );
  serviceLocator.registerFactory<GetLedgersUseCase>(
    () => GetLedgersUseCase(serviceLocator<LedgerRepository>()),
  );
  serviceLocator.registerFactory<CreateLedgerUseCase>(
    () => CreateLedgerUseCase(serviceLocator<LedgerRepository>()),
  );
  serviceLocator.registerFactory<GetLedgerByCodeUseCase>(
    () => GetLedgerByCodeUseCase(serviceLocator<LedgerRepository>()),
  );
  serviceLocator.registerFactory<DeleteLedgerUseCase>(
    () => DeleteLedgerUseCase(serviceLocator<LedgerRepository>()),
  );
  serviceLocator.registerFactory<UpdateLedgerUseCase>(
    () => UpdateLedgerUseCase(serviceLocator<LedgerRepository>()),
  );
  serviceLocator.registerFactory<DeactivateLedgerUseCase>(
    () => DeactivateLedgerUseCase(serviceLocator<LedgerRepository>()),
  );
  serviceLocator.registerFactory<ReactivateLedgerUseCase>(
    () => ReactivateLedgerUseCase(serviceLocator<LedgerRepository>()),
  );
  serviceLocator.registerFactory<GetLedgerTransactionsUseCase>(
    () => GetLedgerTransactionsUseCase(
      serviceLocator<LedgerTransactionRepository>(),
    ),
  );
  serviceLocator.registerFactory<AddLedgerTransactionUseCase>(
    () => AddLedgerTransactionUseCase(
      serviceLocator<LedgerTransactionRepository>(),
    ),
  );
  serviceLocator.registerFactory<GeneralLedgerCubit>(
    () => GeneralLedgerCubit(
      getLedgersUseCase: serviceLocator<GetLedgersUseCase>(),
      deleteLedgerUseCase: serviceLocator<DeleteLedgerUseCase>(),
      deactivateLedgerUseCase: serviceLocator<DeactivateLedgerUseCase>(),
      reactivateLedgerUseCase: serviceLocator<ReactivateLedgerUseCase>(),
      storageService: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<LedgerDetailCubit>(
    () => LedgerDetailCubit(
      getTransactionsUseCase: serviceLocator<GetLedgerTransactionsUseCase>(),
      addTransactionUseCase: serviceLocator<AddLedgerTransactionUseCase>(),
      getLedgerByCodeUseCase: serviceLocator<GetLedgerByCodeUseCase>(),
    ),
  );

  // ── Discounts ─────────────────────────────────────────────────────────────
  serviceLocator.registerLazySingleton<DiscountRemoteDataSource>(
    () => DiscountRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<DiscountRepository>(
    () => DiscountRepositoryImpl(serviceLocator<DiscountRemoteDataSource>()),
  );
  serviceLocator.registerFactory<GetDiscountsUseCase>(
    () => GetDiscountsUseCase(serviceLocator<DiscountRepository>()),
  );
  serviceLocator.registerFactory<CreateDiscountUseCase>(
    () => CreateDiscountUseCase(serviceLocator<DiscountRepository>()),
  );
  serviceLocator.registerFactory<UpdateDiscountUseCase>(
    () => UpdateDiscountUseCase(serviceLocator<DiscountRepository>()),
  );
  serviceLocator.registerFactory<DeleteDiscountUseCase>(
    () => DeleteDiscountUseCase(serviceLocator<DiscountRepository>()),
  );
  serviceLocator.registerFactory<DeactivateDiscountUseCase>(
    () => DeactivateDiscountUseCase(serviceLocator<DiscountRepository>()),
  );
  serviceLocator.registerFactory<ReactivateDiscountUseCase>(
    () => ReactivateDiscountUseCase(serviceLocator<DiscountRepository>()),
  );
  serviceLocator.registerFactory<DiscountCubit>(
    () => DiscountCubit(
      getDiscountsUseCase: serviceLocator<GetDiscountsUseCase>(),
      deleteDiscountUseCase: serviceLocator<DeleteDiscountUseCase>(),
      deactivateDiscountUseCase: serviceLocator<DeactivateDiscountUseCase>(),
      reactivateDiscountUseCase: serviceLocator<ReactivateDiscountUseCase>(),
      storageService: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<DiscountFormCubit>(
    () => DiscountFormCubit(
      createDiscountUseCase: serviceLocator<CreateDiscountUseCase>(),
      updateDiscountUseCase: serviceLocator<UpdateDiscountUseCase>(),
      storageService: serviceLocator<StorageService>(),
    ),
  );

  // ── Invoice catalog (fee structures / other fees / subsidies) ───────────────
  serviceLocator.registerLazySingleton<InvoiceCatalogRemoteDataSource>(
    () =>
        InvoiceCatalogRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<InvoiceCatalogRepository>(
    () => InvoiceCatalogRepositoryImpl(
      serviceLocator<InvoiceCatalogRemoteDataSource>(),
    ),
  );
  serviceLocator.registerFactory<GetFeeStructuresUseCase>(
    () => GetFeeStructuresUseCase(serviceLocator<InvoiceCatalogRepository>()),
  );
  serviceLocator.registerFactory<GetOtherFeesUseCase>(
    () => GetOtherFeesUseCase(serviceLocator<InvoiceCatalogRepository>()),
  );
  serviceLocator.registerFactory<GetSubsidiesUseCase>(
    () => GetSubsidiesUseCase(serviceLocator<InvoiceCatalogRepository>()),
  );
  serviceLocator.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(
      serviceLocator<InvoiceRemoteDataSource>(),
      serviceLocator<CacheManager>(),
    ),
  );
  serviceLocator.registerFactory<CreateInvoiceUseCase>(
    () => CreateInvoiceUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<CheckInvoiceRecipientsUseCase>(
    () => CheckInvoiceRecipientsUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<UpdateInvoiceUseCase>(
    () => UpdateInvoiceUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<DeleteInvoiceUseCase>(
    () => DeleteInvoiceUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<CancelInvoiceUseCase>(
    () => CancelInvoiceUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<IssueInvoiceUseCase>(
    () => IssueInvoiceUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<ResendInvoiceUseCase>(
    () => ResendInvoiceUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<GetInvoiceOverviewUseCase>(
    () => GetInvoiceOverviewUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<GetInvoiceTransactionsUseCase>(
    () => GetInvoiceTransactionsUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<GetInvoicesUseCase>(
    () => GetInvoicesUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<GetInvoiceByCodeUseCase>(
    () => GetInvoiceByCodeUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<GetFamilySummaryUseCase>(
    () => GetFamilySummaryUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<GetFamilyLedgerUseCase>(
    () => GetFamilyLedgerUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<TransactionDetailsCubit>(
    () => TransactionDetailsCubit(
      getFamilyLedger: serviceLocator<GetFamilyLedgerUseCase>(),
      cancelInvoice: serviceLocator<CancelInvoiceUseCase>(),
      deleteInvoice: serviceLocator<DeleteInvoiceUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerLazySingleton<BillingStatementsRemoteDataSource>(
    () => BillingStatementsRemoteDataSourceImpl(
      serviceLocator<ApiClient>().client,
    ),
  );
  serviceLocator.registerLazySingleton<BillingStatementsRepository>(
    () => BillingStatementsRepositoryImpl(
      serviceLocator<BillingStatementsRemoteDataSource>(),
    ),
  );
  serviceLocator.registerFactory<GetBillingStatementsUseCase>(
    () => GetBillingStatementsUseCase(
      serviceLocator<BillingStatementsRepository>(),
    ),
  );
  serviceLocator.registerFactory<AdminStatementsCubit>(
    () => AdminStatementsCubit(
      getStatements: serviceLocator<GetBillingStatementsUseCase>(),
      statementsRepository: serviceLocator<BillingStatementsRepository>(),
      fileDownloadService: serviceLocator<FileDownloadService>(),
    ),
  );
  serviceLocator.registerFactory<ParentStatementsCubit>(
    () => ParentStatementsCubit(
      getStatements: serviceLocator<GetBillingStatementsUseCase>(),
      statementsRepository: serviceLocator<BillingStatementsRepository>(),
      fileDownloadService: serviceLocator<FileDownloadService>(),
    ),
  );
  serviceLocator.registerFactory<TransactionsCubit>(
    () => TransactionsCubit(
      getOverview: serviceLocator<GetInvoiceOverviewUseCase>(),
      getTransactions: serviceLocator<GetInvoiceTransactionsUseCase>(),
      cancelInvoice: serviceLocator<CancelInvoiceUseCase>(),
      deleteInvoice: serviceLocator<DeleteInvoiceUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<FamilySummaryCubit>(
    () => FamilySummaryCubit(
      getFamilySummary: serviceLocator<GetFamilySummaryUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<CreatePaymentUseCase>(
    () => CreatePaymentUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<CreateRefundUseCase>(
    () => CreateRefundUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<ReceivePaymentRefundCubit>(
    () => ReceivePaymentRefundCubit(
      createPayment: serviceLocator<CreatePaymentUseCase>(),
      createRefund: serviceLocator<CreateRefundUseCase>(),
      getFamilyLedger: serviceLocator<GetFamilyLedgerUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<CreateCreditUseCase>(
    () => CreateCreditUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<AddCreditCubit>(
    () => AddCreditCubit(
      createCredit: serviceLocator<CreateCreditUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );

  // ── Auto Pay / Forte payment methods ──
  serviceLocator.registerLazySingleton<AutoPayRemoteDataSource>(
    () => AutoPayRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<AutoPayRepository>(
    () => AutoPayRepositoryImpl(serviceLocator<AutoPayRemoteDataSource>()),
  );
  serviceLocator.registerFactory<GetSchoolForteConfigUseCase>(
    () => GetSchoolForteConfigUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<GetPaymentSettingsUseCase>(
    () => GetPaymentSettingsUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<PaymentSettingsCubit>(
    () => PaymentSettingsCubit(
      getPaymentSettings: serviceLocator<GetPaymentSettingsUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<GetAutoPayStatusUseCase>(
    () => GetAutoPayStatusUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<SetAutoPayStatusUseCase>(
    () => SetAutoPayStatusUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<GetPaymentMethodsUseCase>(
    () => GetPaymentMethodsUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<AddPaymentMethodUseCase>(
    () => AddPaymentMethodUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<SetPrimaryPaymentMethodUseCase>(
    () => SetPrimaryPaymentMethodUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<DeletePaymentMethodUseCase>(
    () => DeletePaymentMethodUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<UpdatePaymentMethodUseCase>(
    () => UpdatePaymentMethodUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<SetAutopayMethodUseCase>(
    () => SetAutopayMethodUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<PayNowCubit>(
    () => PayNowCubit(
      getGuardianFamilyLedger: serviceLocator<GetGuardianFamilyLedgerUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<GuardianPayUseCase>(
    () => GuardianPayUseCase(serviceLocator<AutoPayRepository>()),
  );
  serviceLocator.registerFactory<PayNowAuthorizeCubit>(
    () => PayNowAuthorizeCubit(
      guardianPay: serviceLocator<GuardianPayUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<AutoPayMethodsCubit>(
    () => AutoPayMethodsCubit(
      getForteConfig: serviceLocator<GetSchoolForteConfigUseCase>(),
      getPaymentSettings: serviceLocator<GetPaymentSettingsUseCase>(),
      getStatus: serviceLocator<GetAutoPayStatusUseCase>(),
      setStatus: serviceLocator<SetAutoPayStatusUseCase>(),
      getMethods: serviceLocator<GetPaymentMethodsUseCase>(),
      addMethod: serviceLocator<AddPaymentMethodUseCase>(),
      setPrimary: serviceLocator<SetPrimaryPaymentMethodUseCase>(),
      setAutopay: serviceLocator<SetAutopayMethodUseCase>(),
      deleteMethod: serviceLocator<DeletePaymentMethodUseCase>(),
      updateMethod: serviceLocator<UpdatePaymentMethodUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<GetInvoiceAnalyticsUseCase>(
    () => GetInvoiceAnalyticsUseCase(serviceLocator<InvoiceRepository>()),
  );
  serviceLocator.registerFactory<AnalyticsCubit>(
    () => AnalyticsCubit(
      getAnalytics: serviceLocator<GetInvoiceAnalyticsUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
  serviceLocator.registerFactory<CreateInvoiceCubit>(
    () => CreateInvoiceCubit(
      getFeeStructures: serviceLocator<GetFeeStructuresUseCase>(),
      getOtherFees: serviceLocator<GetOtherFeesUseCase>(),
      getDiscounts: serviceLocator<GetDiscountsUseCase>(),
      getSubsidies: serviceLocator<GetSubsidiesUseCase>(),
      createInvoice: serviceLocator<CreateInvoiceUseCase>(),
      issueInvoice: serviceLocator<IssueInvoiceUseCase>(),
      updateInvoice: serviceLocator<UpdateInvoiceUseCase>(),
      getInvoiceByCode: serviceLocator<GetInvoiceByCodeUseCase>(),
      storage: serviceLocator<StorageService>(),
    ),
  );
}
