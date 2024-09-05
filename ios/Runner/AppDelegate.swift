import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return handleUniversalLink(url)
  }

  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let url = userActivity.webpageURL {
      return handleUniversalLink(url)
    }
    return false
  }

  private func handleUniversalLink(_ url: URL) -> Bool {
    let linkString = url.absoluteString
    if let flutterViewController = window?.rootViewController as? FlutterViewController {
      flutterViewController.engine?.navigationChannel.invokeMethod("pushRoute", arguments: "/deeplink?link=\(linkString)")
    }
    return true
  }
}