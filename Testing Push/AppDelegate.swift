import UIKit
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let remoteMessagingHandler = RemoteMessagingHandler.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FIRApp.configure()
        remoteMessagingHandler.connectToFcm()
        NotificationCenter.default.addObserver(self, selector: #selector(InstanceIdHandler.tokenWasRefreshed(_:)), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        remoteMessagingHandler.requestNotificationsPermission()
        remoteMessagingHandler.registerForRemoteMessages()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        remoteMessagingHandler.disconnectFromFcm()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard let data = userInfo as? [String: Any] else { return }
        remoteMessagingHandler.digestPushData(data)
        completionHandler(.newData)
    }
}

