//
//  WBGlobal.swift
//  WM
//
//  Created by mac-admin on 10/26/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import Foundation
import UIKit

class WMGlobal: NSObject {
    
    // Show Alert
    static func showAlert(title: String, message: String, target: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) {action in
            
        })
        target.present(alertController, animated: true)
    }
    
    // Save UserData
    static func saveUserData(userData: [String: Any?]) {
        let userDefault = UserDefaults(suiteName: "group.com.mobile.waybackmachine")
        do {
            let encodedObject = try NSKeyedArchiver.archivedData(withRootObject: userData, requiringSecureCoding: true)
            userDefault?.set(encodedObject, forKey: "UserData")
            userDefault?.synchronize()
        } catch {
            NSLog("*** saveUserData ERROR: \(error)") // DEBUG
        }
    }
    
    // Get UserData
    static func getUserData() -> [String: Any?]? {
        let userDefault = UserDefaults(suiteName: "group.com.mobile.waybackmachine")
        if let encodedData = userDefault?.data(forKey: "UserData") {
            do {
                let obj = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSDate.self, NSNull.self], from: encodedData) as? [String: Any?]
                return obj
            } catch {
                NSLog("*** getUserData ERROR: \(error)") // DEBUG
            }
        }
        return nil
    }
    
    static func isLoggedIn() -> Bool {
        if let userData = self.getUserData(),
            let isLoggedin = userData["logged-in"] as? Bool,
            isLoggedin == true {
            return true
        }
        return false
    }
    
    static func adjustNavBarHeight(constraint: NSLayoutConstraint) {
        let screenHeight = UIScreen.main.nativeBounds.height
        
        // FIXME: you can tell this ain't future-proof!
        if screenHeight != 2436,
            screenHeight != 2688,
            screenHeight != 1792 {
            constraint.constant = 60
        }
    }
}
