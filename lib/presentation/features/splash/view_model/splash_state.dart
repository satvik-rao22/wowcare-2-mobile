part of 'splash_cubit.dart';

/// Where [SplashCubit] has decided to send the user, or [pending] while
/// still deciding.
enum SplashRoute {
  pending,
  kiosk,
  schoolSelection,
  orgSelection,
  dashboardOrDeepLink,
  signIn,
  // SessionExpiredCoordinator already performed its own navigation — the
  // widget has nothing further to do for this route.
  sessionExpired,
}

class SplashState extends Equatable {
  const SplashState({
    this.route = SplashRoute.pending,
    this.deepLinkLocation,
    this.pendingOrgSchool,
    this.schoolSelectionOrgCode,
  });

  final SplashRoute route;

  /// Resolved notification deep-link location for [SplashRoute.
  /// dashboardOrDeepLink] — falls back to the dashboard route when null.
  final String? deepLinkLocation;

  /// Org/school a killed-state notification targets. Only applied (via a
  /// school switch, which needs a BuildContext — see [SplashCubit]'s own
  /// doc for why that step stays in the widget) when [deepLinkLocation] is
  /// non-null, matching the original splash screen's behaviour.
  final Map<String, String>? pendingOrgSchool;

  /// Org code for [SplashRoute.schoolSelection]'s `extra` payload. Null
  /// means no org was resolved yet, so the widget should route to
  /// org-selection instead.
  final String? schoolSelectionOrgCode;

  SplashState copyWith({
    SplashRoute? route,
    String? deepLinkLocation,
    Map<String, String>? pendingOrgSchool,
    String? schoolSelectionOrgCode,
  }) {
    return SplashState(
      route: route ?? this.route,
      deepLinkLocation: deepLinkLocation ?? this.deepLinkLocation,
      pendingOrgSchool: pendingOrgSchool ?? this.pendingOrgSchool,
      schoolSelectionOrgCode:
          schoolSelectionOrgCode ?? this.schoolSelectionOrgCode,
    );
  }

  @override
  List<Object?> get props => [
    route,
    deepLinkLocation,
    pendingOrgSchool,
    schoolSelectionOrgCode,
  ];
}
