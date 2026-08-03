import Foundation
import Flutter
import CoreLocation
import UserNotifications

final class GeofencePlugin: NSObject, CLLocationManagerDelegate {
  static let methodChannelName = "com.wowcare.geofencing/native"

  private static var instance: GeofencePlugin?
  private var channel: FlutterMethodChannel?
  private let locationManager = CLLocationManager()

  private let prefsSchoolLatKey = "geofence_school_lat"
  private let prefsSchoolLonKey = "geofence_school_lon"
  private let prefsSchoolRadiusKey = "geofence_school_radius_m"
  private let prefsGpsEnabledKey = "geofence_gps_sign_in_enabled"
  private let prefsLastInsideKey = "geofence_last_notified_inside"
  private let prefsNothingToDoKey = "geofence_nothing_to_do"

  static func initializeWithChannel(_ channel: FlutterMethodChannel) {
    if instance == nil {
      instance = GeofencePlugin()
    }
    instance?.channel = channel
    instance?.configure()
  }

  private func configure() {
    locationManager.delegate = self
    // kCLLocationAccuracyNearestTenMeters (≈10 m) gives reliable requestState()
    // results for small geofences without draining the battery as fast as Best.
    // HundredMeters was too coarse — requestState could return .unknown for zones
    // smaller than the accuracy radius, so the initial state was never resolved.
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    // allowsBackgroundLocationUpdates MUST only be set when the app actually has
    // "Always" authorization. Setting it on a .notDetermined or .authorizedWhenInUse
    // CLLocationManager raises an NSInternalInconsistencyException on some iOS
    // versions and can silently prevent location updates from starting.
    // We apply it in handleAuthorizationChange() once "Always" is confirmed.
    // Background region-crossing events still work with "When In Use" in the
    // foreground; "Always" is required only for background + killed-app delivery.
    locationManager.pausesLocationUpdatesAutomatically = false

    // Location permission is requested by the Dart side (GeofenceCubit) once
    // geofencing actually initializes for a school — not here at native init —
    // so the user isn't prompted before there's any context for why, and so
    // there is a single, deliberate request path instead of two racing ones.
    requestNotificationPermission()

    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "updateSchoolLocation":
        self.handleUpdateSchoolLocation(call: call, result: result)
      case "getGeofenceStatus":
        self.handleGetGeofenceStatus(result: result)
      case "updateSignInStatus":
        self.handleUpdateSignInStatus(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Permission helpers

  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      if let error = error {
        print("[iOS PUSH] Notification permission error: \(error.localizedDescription)")
      } else {
        print("[iOS PUSH] Notification permission granted: \(granted)")
      }
    }
  }

  // MARK: - Method channel handlers

  private func handleUpdateSchoolLocation(call: FlutterMethodCall, result: FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
      return
    }

    let latitude = args["latitude"] as? Double ?? 0.0
    let longitude = args["longitude"] as? Double ?? 0.0
    let radiusMeters = args["radiusMeters"] as? Double ?? 250.0
    let schoolCode = args["schoolCode"] as? String ?? "school"
    let gpsEnabled = args["gpsSignInEnabled"] as? Bool ?? true

    if latitude == 0.0 || longitude == 0.0 {
      print("[iOS GEOFENCE] ❌ Invalid school coordinates (lat=\(latitude), lon=\(longitude))")
      result(FlutterError(code: "bad_location", message: "Invalid school coordinates", details: nil))
      return
    }

    print("[iOS GEOFENCE] updateSchoolLocation: school=\(schoolCode) lat=\(latitude) lon=\(longitude) radius=\(radiusMeters)m gpsEnabled=\(gpsEnabled)")

    let defaults = UserDefaults.standard
    defaults.set(latitude, forKey: prefsSchoolLatKey)
    defaults.set(longitude, forKey: prefsSchoolLonKey)
    defaults.set(radiusMeters, forKey: prefsSchoolRadiusKey)
    defaults.set(gpsEnabled, forKey: prefsGpsEnabledKey)
    defaults.set(schoolCode, forKey: "geofence_school_code")

    if !gpsEnabled {
      print("[iOS GEOFENCE] GPS sign-in disabled by admin — stopping region monitoring")
      for region in locationManager.monitoredRegions {
        if region.identifier.hasPrefix("wowcare_geofence_") {
          locationManager.stopMonitoring(for: region)
        }
      }
      result(true)
      return
    }

    startMonitoringRegion(
      identifier: "wowcare_geofence_\(schoolCode)",
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters
    )

    result(true)
  }

  private func handleUpdateSignInStatus(call: FlutterMethodCall, result: FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
      return
    }
    let nothingToDo = args["nothingToDo"] as? Bool ?? false
    UserDefaults.standard.set(nothingToDo, forKey: prefsNothingToDoKey)
    result(true)
  }

  private func handleGetGeofenceStatus(result: FlutterResult) {
    let defaults = UserDefaults.standard
    let lastInside = defaults.bool(forKey: prefsLastInsideKey)
    let gpsEnabled = defaults.object(forKey: prefsGpsEnabledKey) as? Bool ?? true
    print("[iOS GEOFENCE] getGeofenceStatus → isInside=\(lastInside) gpsEnabled=\(gpsEnabled)")
    result([
      "isInside": lastInside,
      "gpsSignInEnabled": gpsEnabled,
    ])
  }

  // MARK: - Region monitoring

  private func startMonitoringRegion(identifier: String, latitude: Double, longitude: Double, radiusMeters: Double) {
    for region in locationManager.monitoredRegions {
      if region.identifier.hasPrefix("wowcare_geofence_") {
        locationManager.stopMonitoring(for: region)
      }
    }

    guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
      print("[iOS GEOFENCE] ❌ Region monitoring not available on this device")
      return
    }

    // Clamp radius: iOS minimum is 1 m, maximum is locationManager.maximumRegionMonitoringDistance.
    let clampedRadius = max(1.0, min(radiusMeters, locationManager.maximumRegionMonitoringDistance))
    if clampedRadius != radiusMeters {
      print("[iOS GEOFENCE] ⚠️ Radius clamped: \(radiusMeters)m → \(clampedRadius)m (device limit)")
    }

    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let region = CLCircularRegion(center: center, radius: clampedRadius, identifier: identifier)
    region.notifyOnEntry = true
    region.notifyOnExit = true

    // Reset retry counter each time a new region is registered so a fresh
    // series of .unknown retries can run if GPS is cold on this session.
    regionStateRetryCount = 0

    locationManager.startMonitoring(for: region)
    // requestState fires didDetermineState immediately so Flutter gets an
    // authoritative inside/outside reading right after registration,
    // without waiting for the user to cross the boundary.
    locationManager.requestState(for: region)
    print("[iOS GEOFENCE] ✅ Monitoring started: \(identifier) radius=\(clampedRadius)m")
  }

  // MARK: - CLLocationManagerDelegate

  // iOS 14+ authorization change callback.
  @available(iOS 14.0, *)
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    print("[iOS LOCATION] Authorization changed (iOS 14+): \(manager.authorizationStatus.rawValue)")
    handleAuthorizationChange(status: manager.authorizationStatus)
  }

  // iOS 13 and below authorization change callback.
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    print("[iOS LOCATION] Authorization changed (iOS 13): \(status.rawValue)")
    handleAuthorizationChange(status: status)
  }

  private func handleAuthorizationChange(status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse:
      // Respect the user's choice — do NOT auto-escalate to "Always". Background/
      // terminated geofencing stays off until the user explicitly grants Always
      // through a deliberate, separate flow (not implemented in this phase).
      // Explicitly disable background updates — covers the downgrade case
      // (Always → While In Use via Settings) where it was previously true.
      print("[iOS LOCATION] Got When In Use — staying foreground-only, no auto-escalation")
      locationManager.allowsBackgroundLocationUpdates = false
    case .authorizedAlways:
      print("[iOS LOCATION] ✅ Got Always authorization — enabling background updates and restarting region monitoring")
      // Safe to enable background updates now that "Always" is confirmed.
      locationManager.allowsBackgroundLocationUpdates = true
      restartMonitoringWithPersistedConfig()
    case .denied:
      print("[iOS LOCATION] ❌ Authorization denied — geofencing disabled")
      locationManager.allowsBackgroundLocationUpdates = false
    case .restricted:
      print("[iOS LOCATION] ❌ Authorization restricted — geofencing disabled")
      locationManager.allowsBackgroundLocationUpdates = false
    default:
      break
    }
  }

  private func restartMonitoringWithPersistedConfig() {
    let defaults = UserDefaults.standard
    let lat = defaults.double(forKey: prefsSchoolLatKey)
    let lon = defaults.double(forKey: prefsSchoolLonKey)
    let radius = defaults.double(forKey: prefsSchoolRadiusKey)
    let schoolCode = defaults.string(forKey: "geofence_school_code") ?? "school"
    guard lat != 0.0 && lon != 0.0 else { return }
    startMonitoringRegion(
      identifier: "wowcare_geofence_\(schoolCode)",
      latitude: lat,
      longitude: lon,
      radiusMeters: radius > 0 ? radius : 250.0
    )
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("[iOS GEOFENCE] ✅ Entered region: \(region.identifier)")
    handleRegionEvent(isInside: true)
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    print("[iOS GEOFENCE] 🚪 Exited region: \(region.identifier)")
    handleRegionEvent(isInside: false)
  }

  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    switch state {
    case .inside:
      print("[iOS GEOFENCE] didDetermineState: inside \(region.identifier)")
      handleRegionEvent(isInside: true, shouldNotify: false)
    case .outside:
      print("[iOS GEOFENCE] didDetermineState: outside \(region.identifier)")
      handleRegionEvent(isInside: false, shouldNotify: false)
    case .unknown:
      // .unknown fires when GPS hasn't locked yet or authorization is only
      // "When In Use" and the system can't evaluate the region in the
      // background. Rather than giving up, request a one-shot location fix
      // to warm up the GPS, then re-evaluate the region state after a short
      // delay so the user isn't permanently stuck with an indeterminate state.
      print("[iOS GEOFENCE] didDetermineState: unknown \(region.identifier) — scheduling GPS warm-up + retry in 6 s")
      scheduleRegionStateRetry(for: region)
    @unknown default:
      break
    }
  }

  // MARK: - Region state retry (unknown recovery)

  /// Requests a one-shot GPS fix so the system can warm up the location
  /// engine, then calls requestState again after [delaySeconds].
  /// Limited to [maxRetries] attempts to avoid an infinite loop if GPS is
  /// genuinely unavailable (e.g. airplane mode, indoor with no signal).
  private var regionStateRetryCount = 0
  private let maxRegionStateRetries = 3

  private func scheduleRegionStateRetry(for region: CLRegion) {
    guard regionStateRetryCount < maxRegionStateRetries else {
      print("[iOS GEOFENCE] ⚠️ Max retry attempts reached for \(region.identifier) — giving up on state determination")
      return
    }
    regionStateRetryCount += 1
    let attempt = regionStateRetryCount
    let delay: Double = Double(attempt) * 6.0   // 6 s, 12 s, 18 s back-off

    // Request a one-shot location fix. This warms up the GPS chip so the
    // next requestState() can return .inside / .outside instead of .unknown.
    locationManager.requestLocation()
    print("[iOS GEOFENCE] 🛰 Requested one-shot location fix (attempt \(attempt)/\(maxRegionStateRetries))")

    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self = self else { return }
      print("[iOS GEOFENCE] 🔄 Retrying requestState for \(region.identifier) (attempt \(attempt)/\(self.maxRegionStateRetries))")
      self.locationManager.requestState(for: region)
    }
  }

  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    print("[iOS GEOFENCE] ❌ Monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
  }

  // Required by CLLocationManagerDelegate when requestLocation() is used.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let loc = locations.last else { return }
    print("[iOS LOCATION] One-shot fix: lat=\(loc.coordinate.latitude) lon=\(loc.coordinate.longitude) accuracy=±\(loc.horizontalAccuracy)m")
    // requestState will now have a valid location context and should resolve
    // to .inside or .outside instead of .unknown on the scheduled retry.
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("[iOS LOCATION] ❌ Location update failed: \(error.localizedDescription)")
  }

  // MARK: - Region event handling

  private func handleRegionEvent(isInside: Bool, shouldNotify: Bool = true) {
    let defaults = UserDefaults.standard
    let gpsEnabled = defaults.object(forKey: prefsGpsEnabledKey) as? Bool ?? true
    guard gpsEnabled else {
      print("[iOS GEOFENCE] Region event ignored — GPS sign-in disabled by admin")
      return
    }

    // De-dup only when a value has been explicitly stored before.
    // UserDefaults.bool(forKey:) returns false by default (key never set), so
    // comparing against it would swallow the very first "outside" event on fresh install.
    if let lastInside = defaults.object(forKey: prefsLastInsideKey) as? Bool,
       lastInside == isInside {
      print("[iOS GEOFENCE] De-dup: state unchanged (isInside=\(isInside)) — skipping")
      return
    }

    defaults.set(isInside, forKey: prefsLastInsideKey)
    print("[iOS GEOFENCE] 📡 Notifying Flutter: isInside=\(isInside)")
    channel?.invokeMethod("geofenceStatusChanged", arguments: ["isInside": isInside])

    guard shouldNotify else { return }

    // "You can now Sign In or Sign Out" is meaningless when staff/admin is
    // already signed in or a guardian's children are all already signed in.
    // Flutter pushes this flag whenever sign-in status changes, so it stays
    // current even when this event fires in the background/killed app.
    if isInside && defaults.bool(forKey: prefsNothingToDoKey) {
      print("[iOS GEOFENCE] Skipping enter notification — nothing to sign in/out")
      return
    }

    showLocalNotification(isInside: isInside)
  }

  // MARK: - Local notification

  private func showLocalNotification(isInside: Bool) {
    let content = UNMutableNotificationContent()
    if isInside {
      content.title = "Sign In/Out"
      content.body = "Tap here to Sign In."
    } else {
      content.title = "You have left the school"
      content.body = "Tap here to Sign Out."
    }
    content.sound = .default
    content.userInfo = ["action": isInside ? "GEOFENCE_ENTER" : "GEOFENCE_EXIT"]

    let request = UNNotificationRequest(
      identifier: isInside ? "wowcare_geofence_enter" : "wowcare_geofence_exit",
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("[iOS GEOFENCE] ❌ Local notification failed: \(error.localizedDescription)")
      } else {
        print("[iOS GEOFENCE] 🔔 Local notification scheduled: isInside=\(isInside)")
      }
    }
  }
}
