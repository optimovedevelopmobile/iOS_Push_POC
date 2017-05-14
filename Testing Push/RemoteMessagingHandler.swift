import Foundation
import UserNotifications
import Firebase

class RemoteMessagingHandler: NSObject {
    
    static let shared = RemoteMessagingHandler()
    
    private override init() {
        
        super.init()
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
        print("Disconnected from FCM!")
    }
    
    func requestNotificationsPermission() {
        
        @available(iOS 10.0, *)
        func requestAuthForUN() {
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        }
        
        func requestAuthForLocal() {
            
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        
        if #available(iOS 10.0, *) {
            requestAuthForUN()
        } else {
            requestAuthForLocal()
        }
    }
    
    func registerForRemoteMessages() {
        
        FIRMessaging.messaging().remoteMessageDelegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
}


//MARK: - Data Messages

extension RemoteMessagingHandler: FIRMessagingDelegate {
    
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        
        guard let data = remoteMessage.appData as? [String: Any] else { return }
        digestPushData(data)
    }
    
    func digestPushData(_ data: [String: Any]) {
        
        FIRMessaging.messaging().appDidReceiveMessage(data)
        guard let title = data["title"] as? String  else { return }
        guard let body = data["body"] as? String else { return }
        
        if #available(iOS 10.0, *) {
            showUNNotification(title: title, body: body)
        } else {
            showLocalNotification(title: title, body: body)
        }
    }
    
    @available(iOS 10.0, *)
    private func showUNNotification(title: String, body: String) {
        
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
    
    private func showLocalNotification(title: String, body: String) {
        
        let notification = UILocalNotification()
        notification.alertTitle = title
        notification.alertBody = body
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.shared.presentLocalNotificationNow(notification)
    }
}
