import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/notifications/cubit/notification_badge_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/theme_cubit.dart';

/// Root-level [MultiProvider] providers — cubits that must be available on
/// every route, including screens pushed onto the root navigator.
List<SingleChildWidget> rootAppProviders() => [
  BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
  BlocProvider<RoleCubit>(create: (_) => RoleCubit()),
  BlocProvider<ParentChildCubit>(
    create: (_) => serviceLocator<ParentChildCubit>(),
  ),
  // Provided at root so CustomAppBar's BlocBuilder<UnreadBadgeCubit>
  // is satisfied on every route — including screens pushed onto the root
  // navigator (AddStudentScreen, EditStudentProfileDetailsScreen, etc.)
  // that are outside the GlobalScaffold subtree.
  // startWatching() is called in GlobalScaffold.initState() after login.
  BlocProvider<UnreadBadgeCubit>(
    create: (_) => serviceLocator<UnreadBadgeCubit>(),
  ),
  // Same rationale as UnreadBadgeCubit: provided at root so CustomAppBar's
  // notification bell badge is satisfied on every route. load() is called
  // in GlobalScaffold.initState() after login.
  BlocProvider<NotificationBadgeCubit>(
    create: (_) => serviceLocator<NotificationBadgeCubit>(),
  ),
];
