import SwiftUI
import FirebaseCore
import GoogleMobileAds

import FirebaseMessaging
import UserNotifications
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    // Initialize Google Mobile Ads SDK
    MobileAds.shared.start(completionHandler: nil)

    // plistの存在確認をしてから設定
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
        FirebaseApp.configure()
        print("Firebase configured successfully.")
        
        // FCM / Notifications Setup
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        
        application.registerForRemoteNotifications()
    } else {
        print("WARNING: GoogleService-Info.plist not found. Firebase not configured.")
    }
      
    return true
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      print("APNS Token received: \(deviceToken)")
      Messaging.messaging().apnsToken = deviceToken
  }
    
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Failed to register for remote notifications: \(error)")
  }
    
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")
      if let token = fcmToken {
          // FirebaseManager経由でTokenを保存
          if let uid = FirebaseManager.shared.auth.currentUser?.uid {
              Task {
                  await FirebaseManager.shared.updateFCMToken(token, uid: uid)
              }
          } else {
              print("FCM Token received but no user logged in.")
          }
      }
  }

  // フォアグラウンドでも通知を表示する
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      let userInfo = notification.request.content.userInfo
      print("Will present notification: \(userInfo)")
      completionHandler([.banner, .badge, .sound])
  }

  // 通知タップ時の処理
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
      let userInfo = response.notification.request.content.userInfo
      print("Did receive response: \(userInfo)")
      completionHandler()
  }
}

@main
struct TeamToDoApp: App {
    // AppDelegateを接続
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
