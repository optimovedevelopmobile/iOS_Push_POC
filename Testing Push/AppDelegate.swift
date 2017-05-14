import UIKit
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FIRApp.configure()
        connectToFcm()
        NotificationCenter.default.addObserver(self, selector: #selector(tokenWasRefreshed(_:)), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        registerForRemoteMessages()
        print("\n\(token ?? "NO TOKEN!!")\n")
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        disconnectFromFcm()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard let data = userInfo as? [String: Any] else { return }
        digestPushData(data)
        completionHandler(.newData)
    }
}

extension AppDelegate {
    
    func registerForRemoteMessages() {
        
        @available(iOS 10.0, *)
        func requestAuthForUN() {
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        }
        
        func requestAuthForLocal() {
            
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        
        func register() {
            
            FIRMessaging.messaging().remoteMessageDelegate = self
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        if #available(iOS 10.0, *) {
            requestAuthForUN()
        } else {
            requestAuthForLocal()
        }
        register()
    }
}


//MARK: - Data Messages
extension AppDelegate: FIRMessagingDelegate {
    
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        
        guard let data = remoteMessage.appData as? [String: Any] else { return }
        digestPushData(data)
    }
    
    func digestPushData(_ data: [String: Any]) {
        
        @available(iOS 10.0, *)
        func showUNNotification(title: String, body: String) {
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default()
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            let request = UNNotificationRequest(identifier: "com.test.not", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                guard error != nil else {
                    print(error!)
                    return
                }
            }
        }
        
        func showLocalNotification(title: String, body: String) {
            
            let notification = UILocalNotification()
            notification.alertTitle = title
            notification.alertBody = body
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
        
        guard let title = data["title"] as? String  else { return }
        guard let body = data["body"] as? String else { return }
        
        if #available(iOS 10.0, *) {
            showUNNotification(title: title, body: body)
        } else {
            showLocalNotification(title: title, body: body)
        }
    }
    
    func connectToFcm() {
        
        guard FIRInstanceID.instanceID().token() != nil else { return }
        disconnectFromFcm()
        FIRMessaging.messaging().connect { error in
            if let error = error {
                print("Unable to connect to FCM due to: \(error)")
            } else {
                print("Connected to FCM!")
            }
        }
    }
    
    func disconnectFromFcm() {
        
        FIRMessaging.messaging().disconnect()
        print("DisconnectedF from FCM!")
    }
}

//MARK: - InstanceID

extension AppDelegate {
    
    var token: String? {
        return FIRInstanceID.instanceID().token()
    }
    
    @objc func tokenWasRefreshed(_ notification: Notification) {
        
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("New refreshed token: \n\(refreshedToken)\n")
        }
        connectToFcm()
    }
}
