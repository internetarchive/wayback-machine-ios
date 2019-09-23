//
//  WelcomeVC.swift
//  WM
//
//  Created by Admin on 10/10/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class WelcomeVC: WMBaseVC {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let userData = WMGlobal.getUserData(),
            let email = userData["email"] as? String,
            let password = userData["password"] as? String {
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            WMAPIManager.sharedManager.login(email: email, password: password) { (data) in
                MBProgressHUD.hide(for: self.view, animated: true)
                guard let data = data, let success = data["success"] as? Bool, success == true else {
                    self.gotoLoginVC()
                    return
                }
                
                let tabbarVC = self.storyboard?.instantiateViewController(withIdentifier: "TabbarVC") as! UITabBarController
                tabbarVC.modalPresentationStyle = .fullScreen
                self.present(tabbarVC, animated: true, completion: nil)
            }
        } else {
            gotoLoginVC()
        }
    }
    
    func gotoLoginVC() {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        self.navigationController?.pushViewController(loginVC, animated: true)
    }

    // MARK: - Actions
    
    
    @IBAction func onSupportPressed(_ sender: Any) {
        let aboutVC = self.storyboard?.instantiateViewController(withIdentifier: "AboutVC") as! AboutViewController
        aboutVC.shouldShowNavbar = true
        self.navigationController?.pushViewController(aboutVC, animated: true)
    }
    
}
