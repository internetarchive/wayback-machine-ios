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
        
        if let userData = WMGlobal.getUserData(), let loggedIn = userData["logged-in"] as? Bool, loggedIn == true {
            // already logged in
            if let tabbarVC = self.storyboard?.instantiateViewController(withIdentifier: "TabbarVC") as? UITabBarController {
                tabbarVC.modalPresentationStyle = .fullScreen
                self.present(tabbarVC, animated: true, completion: nil)
            }
        } else {
            // stay on Welcome VC to signup or login
            //gotoLoginVC()
        }
    }
    
    func gotoLoginVC() {
        if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC {
            self.navigationController?.pushViewController(loginVC, animated: true)
        }
    }

    // MARK: - Actions
    
    
    @IBAction func onSupportPressed(_ sender: Any) {
        if let aboutVC = self.storyboard?.instantiateViewController(withIdentifier: "AboutVC") as? AboutViewController {
            aboutVC.shouldShowNavbar = true
            self.navigationController?.pushViewController(aboutVC, animated: true)
        }
    }
    
}
