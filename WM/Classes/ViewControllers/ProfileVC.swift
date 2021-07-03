//
//  ProfileVC.swift
//  WM
//
//  Created by Admin on 10/12/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit

class ProfileVC: WMBaseVC {

    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var switchMyWebArchive: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: check this!
        if let userData = WMGlobal.getUserData() {
            if let screenname = userData["screenname"] as? String {
                self.lblDescription.text = (self.lblDescription.text ?? "") + screenname
            }
            if let addToMyWebArchive = userData["add-to-my-web-archive"] as? Bool {
                self.switchMyWebArchive.isOn = addToMyWebArchive
            }
        }
    }
    
    
    @IBAction func onSwitchChanged(_ sender: Any) {
        let addToMyWebArchive = switchMyWebArchive.isOn
        if var userData = WMGlobal.getUserData() {
            userData["add-to-my-web-archive"] = addToMyWebArchive
            WMGlobal.saveUserData(userData: userData)
        }
    }
    
    @IBAction func onLogoutPressed(_ sender: Any) {
        // clear any stored login data
        if let userData = WMSAPIManager.shared.logout(userData: WMGlobal.getUserData()) {
            WMGlobal.saveUserData(userData: userData)
        }
        self.tabBarController?.dismiss(animated: false, completion: nil)
    }
    
}
