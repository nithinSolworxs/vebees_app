import UIKit
import Flutter
import flutter_local_notifications   // <-- IMPORTANT

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // ==============================================
    // 🔔 LOCAL NOTIFICATIONS SETUP
    // ==============================================

    // Register callback for flutter_local_notifications
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }

    // Set iOS notification delegate for foreground notifications
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
