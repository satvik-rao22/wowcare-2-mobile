import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // MARK: - FlutterImplicitEngineDelegate

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Wire up the native geofence plugin so CLLocationManager region monitoring
    // and Dart ↔ native method calls work on iOS.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WowCareGeofence") {
      let geofenceChannel = FlutterMethodChannel(
        name: GeofencePlugin.methodChannelName,
        binaryMessenger: registrar.messenger()
      )
      GeofencePlugin.initializeWithChannel(geofenceChannel)
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  // Called when a notification arrives while the app is in the FOREGROUND.
  // FlutterAppDelegate's default implementation passes [] (no presentation),
  // so banners/sounds are suppressed. We override to show our local geofence
  // notifications as banners. FCM foreground presentation is controlled by
  // FirebaseMessaging.setForegroundNotificationPresentationOptions() in Dart.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let id = notification.request.identifier
    if id.hasPrefix("wowcare_geofence_") {
      // Show geofence local notifications as banner + sound when app is open.
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .sound, .badge])
      } else {
        completionHandler([.alert, .sound, .badge])
      }
    } else {
      // All other notifications (FCM): delegate to Flutter/Firebase SDK.
      super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }
  }

  // Called when the user taps a notification (foreground, background, or killed).
  // For geofence notifications we persist the action so Dart can route to /dashboard.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let id = response.notification.request.identifier
    if id.hasPrefix("wowcare_geofence_") {
      if let action = response.notification.request.content.userInfo["action"] as? String {
        print("[iOS PUSH] Geofence notification tapped: action=\(action)")
        UserDefaults.standard.set(action, forKey: "geofence_pending_tap_action")
      }
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
