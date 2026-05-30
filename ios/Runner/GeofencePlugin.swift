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
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = true

    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "updateSchoolLocation":
        self.handleUpdateSchoolLocation(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleUpdateSchoolLocation(call: FlutterMethodCall, result: FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
      return
    }

    let latitude = args["latitude"] as? Double ?? 0.0
    let longitude = args["longitude"] as? Double ?? 0.0
    let radiusMeters = args["radiusMeters"] as? Double ?? 250.0
    let schoolCode = args["schoolCode"] as? String ?? "school"

    if latitude == 0.0 || longitude == 0.0 {
      result(FlutterError(code: "bad_location", message: "Invalid school coordinates", details: nil))
      return
    }

    // Persist for terminated-state processing.
    let defaults = UserDefaults.standard
    defaults.set(latitude, forKey: prefsSchoolLatKey)
    defaults.set(longitude, forKey: prefsSchoolLonKey)
    defaults.set(radiusMeters, forKey: prefsSchoolRadiusKey)

    requestPermissionsIfNeeded()
    startMonitoringRegion(
      identifier: "wowcare_geofence_\(schoolCode)",
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters
    )

    result(true)
  }

  private func requestPermissionsIfNeeded() {
    if CLLocationManager.authorizationStatus() == .notDetermined {
      locationManager.requestAlwaysAuthorization()
    }

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }

  private func startMonitoringRegion(identifier: String, latitude: Double, longitude: Double, radiusMeters: Double) {
    // Stop older monitored regions created by us to avoid duplicates.
    for region in locationManager.monitoredRegions {
      if region.identifier.hasPrefix("wowcare_geofence_") {
        locationManager.stopMonitoring(for: region)
      }
    }

    guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let region = CLCircularRegion(center: center, radius: radiusMeters, identifier: identifier)
    region.notifyOnEntry = true
    region.notifyOnExit = true

    locationManager.startMonitoring(for: region)
    locationManager.requestState(for: region)
  }

  // MARK: CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    handleRegionEvent(isInside: true)
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    handleRegionEvent(isInside: false)
  }

  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    switch state {
    case .inside:
      handleRegionEvent(isInside: true, shouldNotify: false)
    case .outside:
      handleRegionEvent(isInside: false, shouldNotify: false)
    default:
      break
    }
  }

  private func handleRegionEvent(isInside: Bool, shouldNotify: Bool = true) {
    let defaults = UserDefaults.standard
    let lastInside = defaults.bool(forKey: prefsLastInsideKey)
    if lastInside == isInside {
      // De-dup.
      channel?.invokeMethod("geofenceStatusChanged", arguments: ["isInside": isInside])
      return
    }

    defaults.set(isInside, forKey: prefsLastInsideKey)
    channel?.invokeMethod("geofenceStatusChanged", arguments: ["isInside": isInside])

    guard shouldNotify else { return }
    showLocalNotification(isInside: isInside)
  }

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

    let request = UNNotificationRequest(
      identifier: isInside ? "wowcare_geofence_enter" : "wowcare_geofence_exit",
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }
}

