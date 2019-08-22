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
        
        if let userData = WMGlobal.getUserData(),
            let screenname = userData["screenname"] as? String,
            let addToMyWebArchive = userData["add-to-my-web-archive"] as? Bool {
            self.lblDescription.text = self.lblDescription.text! + screenname
            self.switchMyWebArchive.isOn = addToMyWebArchive
        }
        
    }
    
    
    @IBAction func onSwitchChanged(_ sender: Any) {
        let addToMyWebArchive = switchMyWebArchive.isOn
        var userData = WMGlobal.getUserData()
        userData!["add-to-my-web-archive"] = addToMyWebArchive
        WMGlobal.saveUserData(userData: userData!)
    }
    
    @IBAction func onLogoutPressed(_ sender: Any) {
        WMGlobal.saveUserData(userData: [
            "email"             : nil,
            "password"          : nil,
            "screenname"        : nil,
            "logged-in"         : false,
            "logged-in-user"    : nil,
            "logged-in-sig"     : nil,
            "s3accesskey"       : nil,
            "s3secretkey"       : nil,
            "add-to-my-web-archive" : false
        ])
        
        self.tabBarController?.dismiss(animated: false, completion: nil)
    }
    
}
