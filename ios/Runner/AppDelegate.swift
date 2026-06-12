import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Stores the action from a geofence notification tap so Dart can read it
  // once the Flutter engine starts (userNotificationCenter fires after
  // didFinishLaunchingWithOptions, so we persist it here then read on demand).
  private static let geofenceTapKey = "geofence_pending_tap_action"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Note: window?.rootViewController is nil at this point in newer iOS versions
    // Geofence and method channels are now set up in the FlutterImplicitEngineBridge
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
      let action = response.notification.request.content.userInfo["action"] as? String
      if let action = action {
        UserDefaults.standard.set(action, forKey: AppDelegate.geofenceTapKey)
      }
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

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
}
