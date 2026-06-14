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

  static func initializeWithChannel(_ channel: FlutterMethodChannel) {
    if instance == nil {
      instance = GeofencePlugin()
    }
    instance?.channel = channel
    instance?.configure()
  }

  private func configure() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

    // Request location + notification permissions at app launch so the system
    // prompts appear immediately, not delayed until school data loads.
    requestLocationPermission()
    requestNotificationPermission()

    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "updateSchoolLocation":
        self.handleUpdateSchoolLocation(call: call, result: result)
      case "getGeofenceStatus":
        self.handleGetGeofenceStatus(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Permission helpers

  /// Two-step iOS location permission flow:
  ///   Step 1 (.notDetermined) → requestWhenInUseAuthorization()
  ///   Step 2 (.authorizedWhenInUse) → requestAlwaysAuthorization()
  /// iOS 14+ only shows the "Always Allow" system prompt after the user has
  /// first granted "When In Use" — calling requestAlwaysAuthorization() on a
  /// .notDetermined status skips straight to the When-In-Use dialog anyway,
  /// but being explicit avoids subtle ordering issues on some iOS versions.
  private func requestLocationPermission() {
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = locationManager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }

    switch status {
    case .notDetermined:
      print("[iOS LOCATION] Status: notDetermined → requesting When In Use")
      locationManager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse:
      print("[iOS LOCATION] Status: authorizedWhenInUse → requesting Always")
      locationManager.requestAlwaysAuthorization()
    case .authorizedAlways:
      print("[iOS LOCATION] Status: authorizedAlways ✅ — no request needed")
    case .denied:
      print("[iOS LOCATION] Status: denied ❌ — user must enable in Settings")
    case .restricted:
      print("[iOS LOCATION] Status: restricted ❌ — parental controls active")
    @unknown default:
      print("[iOS LOCATION] Status: unknown (\(status.rawValue))")
    }
  }

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

    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let region = CLCircularRegion(center: center, radius: radiusMeters, identifier: identifier)
    region.notifyOnEntry = true
    region.notifyOnExit = true

    locationManager.startMonitoring(for: region)
    locationManager.requestState(for: region)
    print("[iOS GEOFENCE] ✅ Monitoring started: \(identifier) radius=\(radiusMeters)m")
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
      // User granted "When In Use" — now escalate to "Always" for background monitoring.
      print("[iOS LOCATION] Got When In Use → requesting Always for background geofencing")
      locationManager.requestAlwaysAuthorization()
    case .authorizedAlways:
      print("[iOS LOCATION] ✅ Got Always authorization — restarting region monitoring")
      restartMonitoringWithPersistedConfig()
    case .denied:
      print("[iOS LOCATION] ❌ Authorization denied — geofencing disabled")
    case .restricted:
      print("[iOS LOCATION] ❌ Authorization restricted — geofencing disabled")
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
      print("[iOS GEOFENCE] didDetermineState: unknown \(region.identifier)")
    @unknown default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    print("[iOS GEOFENCE] ❌ Monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
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
    showLocalNotification(isInside: isInside)
  }

  // MARK: - Local notification

  private func showLocalNotification(isInside: Bool) {
    let content = UNMutableNotificationContent()
    if isInside {
      content.title = "Attendance Enabled"
      content.body = "You are within the school radius. You can now sign in."
    } else {
      content.title = "Attendance Disabled"
      content.body = "You moved outside the allowed school radius."
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
