//
//  SignupVC.swift
//  WM
//
//  Created by Admin on 10/10/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class SignupVC: WMBaseVC, UITextFieldDelegate {

    @IBOutlet weak var txtUsername: SkyFloatingLabelTextField!
    @IBOutlet weak var txtEmail: SkyFloatingLabelTextField!
    @IBOutlet weak var txtPassword: SkyFloatingLabelTextField!
    @IBOutlet weak var txtConfirm: SkyFloatingLabelTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtUsername.delegate = self
        txtEmail.delegate = self
        txtPassword.delegate = self
        txtConfirm.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func onSignupPressed(_ sender: Any) {
        if self.txtUsername.text!.isEmpty {
            self.txtUsername.errorMessage = "Username is required"
            return
        } else if self.txtEmail.text!.isEmpty {
            self.txtEmail.errorMessage = "Email is required"
            return
        } else if self.txtPassword.text!.isEmpty {
            self.txtPassword.errorMessage = "Password is required"
            return
        } else if self.txtConfirm.text!.isEmpty {
            self.txtConfirm.errorMessage = "Confirm your password"
            return
        } else if self.txtPassword.text! != self.txtConfirm.text! {
            WMGlobal.showAlert(title: "", message: "Password does not match", target: self)
            self.txtPassword.text = ""
            self.txtConfirm.text = ""
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        WMAPIManager
            .sharedManager
            .registerAccount(
                params: [
                "verified"      : false,
                "email"         : self.txtEmail.text!,
                "password"      : self.txtPassword.text!,
                "screenname"    : self.txtUsername.text!,
                ],
                completion: {(data)in
                
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if data == nil {
                    WMGlobal.showAlert(title: "", message: "Server error", target: self)
                } else {
                    let success = data!["success"] as! Bool
                    
                    if (success) {
                        WMGlobal.saveUserData(userData: [
                            "username"  : self.txtUsername.text!,
                            "email"     : self.txtEmail.text!,
                            "password"  : self.txtPassword.text!
                            ])
                        let alertController = UIAlertController(title: "Action Required", message: "We just sent verification email. Please try to verify your account and login.", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default) {action in
                            self.dismiss(animated: true, completion: nil)
                        })
                        self.present(alertController, animated: true)
                    } else {
                        WMGlobal.showAlert(title: "", message: "Username is already in use", target: self)
                    }
                }
        }
        )
    }
    
    // MARK: - Delegates
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let txtField = textField as? SkyFloatingLabelTextField {
            txtField.errorMessage = nil
        }
        
        return true
    }
}
