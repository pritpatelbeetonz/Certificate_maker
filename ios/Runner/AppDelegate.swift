import UIKit
import Flutter
import google_mobile_ads
import FirebaseCore
import FacebookCore
import UserNotifications

var btnBgColor: String = "#0091FF"
var btnBgColorG1: String = "#0091FF"
var btnBgColorG2: String = "#0091FF"
var btnTextColor: String = "#FFFFFF"
var headerTextColor: String = "#000000"
var bodyTextColor: String = "#000000"
var nativeBGColor: String = "#141414"

@UIApplicationMain

@objc class AppDelegate: FlutterAppDelegate  {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Firebase Config
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        GeneratedPluginRegistrant.register(with: self)

        // Native ads Big , full and Small :
        let listTileBig = BigNativeAdFactory()
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self, factoryId: "bigNativeAds", nativeAdFactory: listTileBig)
        let listTileSmall = SmallNativeAdFactory()
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self, factoryId: "smallNativeAds", nativeAdFactory: listTileSmall)
        let listTileFull = FullNativeAdFactory()
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            self, factoryId: "fullNativeAds", nativeAdFactory: listTileFull)

        // Method channels: use plugin registrar for safe access without relying on window?.rootViewController (UISceneDelegate compatible)
        if let registrar = self.registrar(forPlugin: "Runner") {
            let batteryChannel = FlutterMethodChannel(name: "nativeChannel",
                                                      binaryMessenger: registrar.messenger())
            batteryChannel.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
                guard let self = self else { return }
                // Note: this method is invoked on the UI thread.
                guard call.method == "setToast" else {
                    result(FlutterMethodNotImplemented)
                    return
                }

                // Fetch colors code from firebase remote config
                let myresult = call.arguments as? [String: Any]
                let isPurchase = myresult?["isPurchase"] as? String
                let value1 = myresult?["fb_appid"] as? String
                let value2 = myresult?["fb_token"] as? String

                btnBgColor = (myresult?["btnBgColor"] as? String) ?? (myresult?["btnBgColorG1"] as? String) ?? "#0091FF"
                btnBgColorG1 = (myresult?["btnBgColorG1"] as? String) ?? btnBgColor
                btnBgColorG2 = (myresult?["btnBgColorG2"] as? String) ?? btnBgColor
                btnTextColor = (myresult?["btnTextColor"] as? String) ?? "#FFFFFF"
                headerTextColor = (myresult?["headerTextColor"] as? String) ?? "#000000"
                bodyTextColor = (myresult?["bodyTextColor"] as? String) ?? "#000000"
                nativeBGColor = (myresult?["nativeBGColor"] as? String) ?? "#141414"

                if let v1 = value1, !v1.isEmpty {
                    Settings.appID = v1
                }
                if let v2 = value2, !v2.isEmpty {
                    Settings.clientToken = v2
                }
                Settings.isAutoLogAppEventsEnabled = true
            })

            let notificationChannel = FlutterMethodChannel(name: "notificationChannel",
                                                           binaryMessenger: registrar.messenger())
            notificationChannel.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
                guard let self = self else { return }
                // Note: this method is invoked on the UI thread.
                guard call.method == "setNotification" else {
                    result(FlutterMethodNotImplemented)
                    return
                }

                let myresult = call.arguments as? [String: Any]
                let isPurchase = myresult?["isPurchase"] as? String
                DispatchQueue.main.async {
                    if isPurchase == "false" {
                        // delegate for notification :
                        UNUserNotificationCenter.current().delegate = self

                        // calling for notification:
                        UNUserNotificationCenter.current().getNotificationSettings { settings in
                            switch settings.authorizationStatus {
                            case .notDetermined:
                                self.requestAuthorization()
                            case .authorized, .provisional:
                                self.sendNotification()
                            default:
                                break // Do nothing
                            }
                        }
                    }
                }
            })
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)


    }

    // method for notification :
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            (granted, error) in
            if granted {
                self.sendNotification()
                print("Yes")
            } else {
                print("No")
            }
        }
    }
    // method for notification :
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Certificate Maker"
        content.body = "Design and customize stunning certificates and templates effortlessly!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 00
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // Call method from flutter side and display toast
    func showToast(controller: UIViewController, message : String, seconds: Double){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .black
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        controller.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds){
            alert.dismiss(animated: true)
        }
    }
}

