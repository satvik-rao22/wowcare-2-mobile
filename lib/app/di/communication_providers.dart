import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';

/// Passthrough resolvers for the cubits the communication views provide through
/// `BlocProvider`, kept OUT of the presentation layer (Mandate 5: views
/// reference no `serviceLocator`). Each returns exactly what the view used to
/// resolve inline — the same service-locator registration, no behaviour change.
CommunicationCubit resolveCommunicationCubit() =>
    serviceLocator<CommunicationCubit>();

StaffCubit resolveStaffCubit() => serviceLocator<StaffCubit>();

StudentCubit resolveStudentCubit() => serviceLocator<StudentCubit>();

ClassroomCubit resolveClassroomCubit() => serviceLocator<ClassroomCubit>();

UnreadBadgeCubit resolveUnreadBadgeCubit() => serviceLocator<UnreadBadgeCubit>();
