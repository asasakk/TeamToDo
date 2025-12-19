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

import AppTrackingTransparency
import AdSupport

@main
struct TeamToDoApp: App {
    // AppDelegateを接続
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // ScenePhaseを利用してアプリアクティブ時にATTリクエストを送る
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var orgManager = OrganizationManager()
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0 
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(orgManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    requestTrackingAuthorization()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .preferredColorScheme(appearanceMode == 0 ? nil : (appearanceMode == 1 ? .light : .dark))
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Scheme: teamtodo://join?code=XXXXXX
        guard url.scheme == "teamtodo", url.host == "join" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
            print("Deep Link Invite Code: \(code)")
            orgManager.pendingInviteCode = code
        }
    }
    
    private func requestTrackingAuthorization() {
        // iOS 14以降でのみ実行
        if #available(iOS 14, *) {
            // 少し遅延させてからリクエスト（アプリ起動直後は表示されないことがあるため）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("Authorized")
                        print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
                    case .denied:
                        print("Denied")
                    case .restricted:
                        print("Restricted")
                    case .notDetermined:
                        print("Not Determined")
                    @unknown default:
                        print("Unknown")
                    }
                }
            }
        }
    }
}
