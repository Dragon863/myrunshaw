import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(name: "runshaw/widget", binaryMessenger: controller.binaryMessenger)
      widgetChannel.setMethodCallHandler { call, flutterResult in
        if call.method == "hasWidget" {
          let defaults = UserDefaults(suiteName: "group.uk.danieldb.myrunshaw")
          let hasBalance = defaults?.object(forKey: "runshawpay_balance") != nil
          let hasStatus = defaults?.object(forKey: "runshawpay_status") != nil
          flutterResult(hasBalance || hasStatus)
        } else {
          flutterResult(FlutterMethodNotImplemented)
        }
      }
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
