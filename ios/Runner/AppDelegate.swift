import Flutter
import UIKit
import Firebase // Firebase'i ekleyin
import UserNotifications // Bildirimler için gerekli

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // FCM token'ını al
    Messaging.messaging().token { token, error in
      if let error = error {
        print("FCM token fetch error: \(error)")
      } else if let token = token {
        print("FCM token: \(token)")
      }
    }
    
    // iOS 10 ve sonrası için bildirim yetkisini ayarla
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if let error = error {
            print("Notification authorization error: \(error)")
          } else {
            print("Notification permission granted: \(granted)")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    // Uzak bildirimleri etkinleştir
    application.registerForRemoteNotifications()
    
    // Flutter pluginleri kaydet
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Gelen bildirimleri işler
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .badge, .sound])
  }
}
