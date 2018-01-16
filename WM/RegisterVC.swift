//
//  SignUpVC.swift
//  WM
//
//  Created by mac-admin on 10/25/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class RegisterVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirm: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtUsername.delegate = self
        txtEmail.delegate = self
        txtPassword.delegate = self
        txtConfirm.delegate = self
        
        // TapGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func _onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    
    @IBAction func _onContinue(_ sender: Any) {
        if (self.txtUsername.text!.isEmpty) {
            WMGlobal.showAlert(title: "", message: "Please enter your username", target: self)
            return
        }
        if (self.txtEmail.text!.isEmpty) {
            WMGlobal.showAlert(title: "", message: "Please enter your email", target: self)
            return
        }
        if (self.txtPassword.text!.isEmpty) {
            WMGlobal.showAlert(title: "", message: "Please enter your password", target: self)
            return
        }
        if (self.txtConfirm.text!.isEmpty) {
            WMGlobal.showAlert(title: "", message: "Please confirm your password", target: self)
            return
        }
        if (self.txtPassword.text! != self.txtConfirm.text!) {
            WMGlobal.showAlert(title: "", message: "Password does not match", target: self)
            self.txtPassword.text = ""
            self.txtConfirm.text = ""
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        WMAPIManager.sharedManager.registerAccount(
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
                        let alertController = UIAlertController(title: "Action Required", message: "We just sent verification email. Please try to verify your account.", preferredStyle: .actionSheet)
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
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //- MARK: UITextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
