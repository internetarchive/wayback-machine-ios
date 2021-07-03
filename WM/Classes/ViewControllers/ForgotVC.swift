//
//  ForgotVC.swift
//  WM
//
//  Created by Admin on 10/10/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class ForgotVC: WMBaseVC {

    @IBOutlet weak var txtEmail: SkyFloatingLabelTextField!
    @IBOutlet weak var navBarHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WMGlobal.adjustNavBarHeight(constraint: navBarHeight)
    }
    
    @IBAction func onBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onSubmitPressed(_ sender: Any) {
        guard let email = txtEmail.text, !email.isEmpty else {
            WMGlobal.showAlert(title: "", message: "Please type your email", target: self)
            return
        }
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Resetting..."

        WMSAPIManager.shared.resetPassword(email: email) { (success) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.txtEmail.text = ""
            
            if success {
                let alertController = UIAlertController(title: "Success", message: "We've sent an email with instructions to help you reset password.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default) {action in
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alertController, animated: true)
            } else {
                WMGlobal.showAlert(title: "Failure", message: "Please check your internet connection.", target: self)
            }
        }
    }

}
