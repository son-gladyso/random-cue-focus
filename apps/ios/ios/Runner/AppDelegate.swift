import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "random_cue_focus/pending_notifications",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "pending" || call.method == "removePendingFocus" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let center = UNUserNotificationCenter.current()
      center.getPendingNotificationRequests { requests in
        // This thread is reserved for focus reminders, including pre-upgrade
        // requests whose payload does not identify their owner.
        let belongsToFocus: (UNNotificationRequest) -> Bool = {
          $0.content.threadIdentifier == "random-cue-focus"
        }
        if call.method == "pending" {
          let pending = Dictionary(uniqueKeysWithValues: requests.map {
            ($0.identifier, belongsToFocus($0))
          })
          DispatchQueue.main.async { result(pending) }
        } else {
          let ids = requests.filter(belongsToFocus).map(\.identifier)
          if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
          }
          DispatchQueue.main.async { result(nil) }
        }
      }
    }
  }
}
