import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import flutter_local_notifications
import flutter_background_service_ios

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  var locationManager: CLLocationManager?
  var wifiInfoResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FirebaseApp.configure()
 GeneratedPluginRegistrant.register(with: self)
    // Initialize FlutterLocalNotificationsPlugin
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    SwiftFlutterBackgroundServicePlugin.taskIdentifier = "com.slice.connfy.locationUpdates"

    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      } else {
        if let error = error {
          print("Error requesting notification permissions: \(error.localizedDescription)")
        }
      }
    }

    // Setup Flutter method channel
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let wifiInfoChannel = FlutterMethodChannel(name: "wifi_info", binaryMessenger: controller.binaryMessenger)

    wifiInfoChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getWifiSSID" {
        self.getWifiSSID(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func getWifiSSID(result: @escaping FlutterResult) {
    self.wifiInfoResult = result
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.requestWhenInUseAuthorization()
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status == .authorizedWhenInUse || status == .authorizedAlways {
      if let interfaces = CNCopySupportedInterfaces() as? [String] {
        for interface in interfaces {
          if let currentNetworkInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: AnyObject] {
            wifiInfoResult?(currentNetworkInfo[kCNNetworkInfoKeySSID as String] as? String)
            return
          }
        }
      }
      wifiInfoResult?(nil)
    } else {
      wifiInfoResult?(nil)
    }
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle notification registration failures
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
