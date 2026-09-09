import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/cubit/student_cubit.dart';

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
