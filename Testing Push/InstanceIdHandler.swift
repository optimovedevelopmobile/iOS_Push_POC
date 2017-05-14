import Foundation
import Firebase

class InstanceIdHandler {
    
    static let shared = InstanceIdHandler()
    
    private init() {
        
    }
    
    var token: String? {
        return FIRInstanceID.instanceID().token()
    }
    
    @objc func tokenWasRefreshed(_ notification: Notification) {
        
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("New refreshed token: \n\(refreshedToken)\n")
        }
        RemoteMessagingHandler.shared.connectToFcm()
    }
    
    func setToken(_ token: Data) {
        
        FIRInstanceID.instanceID().setAPNSToken(token, type: .sandbox)
    }
}
