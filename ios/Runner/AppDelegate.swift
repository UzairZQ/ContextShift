import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let storageChannel = FlutterMethodChannel(
        name: "context_shift/device_storage",
        binaryMessenger: controller.binaryMessenger
      )
      storageChannel.setMethodCallHandler { call, result in
        guard call.method == "getStorageInfo" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(Self.storageInfo())
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private static func storageInfo() -> [String: Int64?] {
    do {
      let values = try FileManager.default
        .attributesOfFileSystem(forPath: NSHomeDirectory())
      let available = values[.systemFreeSize] as? NSNumber
      let total = values[.systemSize] as? NSNumber
      return [
        "availableBytes": available?.int64Value,
        "totalBytes": total?.int64Value
      ]
    } catch {
      return [
        "availableBytes": nil,
        "totalBytes": nil
      ]
    }
  }
}
