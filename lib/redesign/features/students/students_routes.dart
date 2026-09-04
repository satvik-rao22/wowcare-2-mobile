import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/app_router.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/add_student_page.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/edit_student_page.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/student_documents_page.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/student_profile_page.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/students_page.dart';

/// M05 Students routes.
///
/// Nested under the dashboard branch with **relative** paths (no leading
/// slash), so back returns to the dashboard and no tab lights up.
/// Absolute paths for navigation live in `AppRoutes`.
///
/// The roster stays inside the shell: it is a list, and the five slots are
/// still where you would want to go next. Everything under it covers the tab
/// bar with `parentNavigatorKey: rootNavigatorKey`, because each of them owns
/// the bottom of its own screen: the record has its two keys, the wizard has
/// its Back and Next, the edit form has Cancel and Save.
///
/// The path parameter is `studentId` rather than `id`: go_router checks path
/// parameter names across the **whole** route tree, so a bare `id` would
/// collide with the next module that wants one.
final List<RouteBase> studentsRoutes = <RouteBase>[
  GoRoute(
    path: 'students',
    builder: (context, state) => const StudentsPage(),
    routes: <RouteBase>[
      // Before `:studentId`, so "new" is a screen rather than a student.
      GoRoute(
        path: 'new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddStudentPage(),
      ),
      GoRoute(
        path: ':studentId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            StudentProfilePage(studentId: state.pathParameters['studentId']!),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) =>
                EditStudentPage(studentId: state.pathParameters['studentId']!),
          ),
          GoRoute(
            path: 'documents',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => StudentDocumentsPage(
              // The profile passes the name and the classroom it already
              // holds; a deep link arrives with only the id and the screen
              // fetches the rest.
              args:
                  state.extra as StudentDocumentsArgs? ??
                  StudentDocumentsArgs(
                    studentId: state.pathParameters['studentId']!,
                  ),
            ),
          ),
        ],
      ),
    ],
  ),
];
