import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // MARK: - UIApplicationDelegate

  // Overriding didFinishLaunchingWithOptions lets us check for a background
  // location relaunch (UIApplication.LaunchOptionsKey.location). When iOS
  // terminates the app and the device crosses a CLCircularRegion boundary, iOS
  // relaunches the process with this key set. CLLocationManager then calls
  // didEnterRegion / didExitRegion on GeofencePlugin, which shows the local
  // notification. Checking the key here signals to the OS that we handle this
  // relaunch scenario intentionally, improving reliability on subsequent kills.
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if launchOptions?[.location] != nil {
      print("[iOS GEOFENCE] App relaunched by OS for location event — CLLocationManager delegate will handle the pending region transition")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

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

    // Wire up the geofence-tap channel so Dart's _readIosGeofenceTap() can
    // retrieve the action stored by AppDelegate.userNotificationCenter(_:didReceive:)
    // when the user taps a geofence notification from killed or background state.
    // Without this handler the channel call returns null silently and the app
    // opens to its default screen instead of the attendance dashboard.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WowCareGeofenceTap") {
      let tapChannel = FlutterMethodChannel(
        name: "wowcare/geofence_tap",
        binaryMessenger: registrar.messenger()
      )
      tapChannel.setMethodCallHandler { call, result in
        guard call.method == "getPendingAction" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let action = UserDefaults.standard.string(forKey: "geofence_pending_tap_action")
        // Consume the value so a second call (e.g. hot-restart) does not re-route.
        UserDefaults.standard.removeObject(forKey: "geofence_pending_tap_action")
        print("[iOS GEOFENCE] getPendingAction → \(action ?? "nil")")
        result(action)
      }
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
