import Foundation
import UserNotifications
import Firebase

let kStoredDataKey = "stored_data"

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
        
        func getPayload() -> [String: Any]? {
            
            let payloadRawString = data["gcm.notification.data"] as? String
            guard let payloadRawData = payloadRawString?.data(using: .utf8) else {
                return nil
            }
            let payload = try? JSONSerialization.jsonObject(with: payloadRawData, options: .allowFragments)
            return payload as? [String: Any]
        }
        
        guard let payload = getPayload() else { return }
        FIRMessaging.messaging().appDidReceiveMessage(data)
        guard let title = payload["titlez"] as? String  else { return }
        guard let body = payload["bodyz"] as? String else { return }
        guard let shouldShow = payload["shouldShow"] as? Bool else { return }
        
        if shouldShow {
            if #available(iOS 10.0, *) {
                showUNNotification(title: title, body: body)
            } else {
                showLocalNotification(title: title, body: body)
            }
        } else {
            UserDefaults.standard.set("\(title)-\(body)", forKey: kStoredDataKey)
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
