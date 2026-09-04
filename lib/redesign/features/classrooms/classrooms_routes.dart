import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/app_router.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/assign_page.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/classroom_page.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/classroom_profile_page.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/classrooms_page.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/create_classroom_page.dart';

/// M07 Classrooms routes.
///
/// [buildClassroomsRoot] draws the branch root at its shell slot;
/// [classroomsRoutes] are nested under it with **relative** paths. They stay
/// relative even where they cover the tab bar: go_router concatenates a
/// child's path onto its parent's, so an absolute `/classrooms/new` under
/// `/classrooms` would resolve to `/classrooms/classrooms/new`. What takes a
/// screen over the tab bar is `parentNavigatorKey: rootNavigatorKey`, which
/// pushes it on the root navigator; the composed path is still the one in
/// `AppRoutes`.
///
/// `new` is declared before `:id` because go_router matches in order, and
/// `/classrooms/new` would otherwise open a classroom whose code is "new".
///
/// Absolute paths for navigation live in `AppRoutes`:
/// `/classrooms`, `/classrooms/new`, `/classrooms/:id`,
/// `/classrooms/:id/profile`, `/classrooms/:id/assign-students` and
/// `/classrooms/:id/assign-staff`.
Widget buildClassroomsRoot(BuildContext context, GoRouterState state) =>
    const ClassroomsPage();

final List<RouteBase> classroomsRoutes = <RouteBase>[
  GoRoute(
    path: 'new',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const CreateClassroomPage(),
  ),
  GoRoute(
    path: ':id',
    builder: (context, state) =>
        ClassroomPage(classroomId: state.pathParameters['id']!),
    routes: <RouteBase>[
      GoRoute(
        path: 'profile',
        builder: (context, state) =>
            ClassroomProfilePage(classroomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'assign-students',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AssignPage(
          classroomId: state.pathParameters['id']!,
          kind: AssignKind.students,
        ),
      ),
      GoRoute(
        path: 'assign-staff',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AssignPage(
          classroomId: state.pathParameters['id']!,
          kind: AssignKind.staff,
        ),
      ),
    ],
  ),
];
