//
//  LoginVC.swift
//  WM
//
//  Created by mac-admin on 10/25/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import MBProgressHUD

class LoginVC: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var containerLogin: UIView!
    @IBOutlet weak var containerLogout: UIView!
    @IBOutlet weak var lblDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtEmail.delegate = self
        txtPassword.delegate = self
        
        // TapGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if let userData = WMGlobal.getUserData(),
            let isLoggedin = userData["logged-in"] as? Bool,
            isLoggedin == true
        {
            self.lblDescription.text = self.lblDescription.text! + (userData["screenname"] as! String)
            self.containerLogin.layer.isHidden = true
            self.containerLogout.layer.isHidden = false
        } else {
            self.containerLogin.layer.isHidden = false
            self.containerLogout.layer.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func _onLogin(_ sender: Any) {
        if (self.txtEmail.text!.isEmpty) {
            WMGlobal.showAlert(title: "", message: "Please enter your email", target: self)
            return
        }
        
        if (self.txtPassword.text!.isEmpty) {
            WMGlobal.showAlert(title: "", message: "Please enter your password", target: self)
            return
        }
        login(email: self.txtEmail.text!, password: self.txtPassword.text!)
    }
    
    @IBAction func _onLogout(_ sender: Any) {
        self.containerLogin.layer.isHidden = false
        self.containerLogout.layer.isHidden = true
        WMGlobal.saveUserData(userData: [
            "email"             : nil,
            "password"          : nil,
            "screenname"        : nil,
            "logged-in"         : false,
            "logged-in-user"    : nil,
            "logged-in-sig"     : nil
        ])
    }
    
    func login(email: String, password: String) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        WMAPIManager.sharedManager.login(email: email, password: password, completion: {(data) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if data == nil {
                WMGlobal.showAlert(title: "", message: "Server error", target: self)
            } else {
                let success = data!["success"] as! Bool
                
                if (success) {
                    WMAPIManager.sharedManager.getAccountInfo(email: email, completion: { (data) in
                        
                        WMAPIManager.sharedManager.getCookieData(email: email, password: password, completion: { (cookieData) in
                            
                            let values = data!["values"] as! [String: Any]
                            let screenname = values["screenname"] as! String
                            self.lblDescription.text = self.lblDescription.text! + screenname
                            self.containerLogin.layer.isHidden = true
                            self.containerLogout.layer.isHidden = false
                            
                            WMGlobal.saveUserData(userData: [
                                "email"             : email,
                                "password"          : password,
                                "screenname"        : screenname,
                                "logged-in"         : true,
                                "logged-in-user"    : cookieData["logged-in-user"],
                                "logged-in-sig"     : cookieData["logged-in-sig"]
                            ])
                        })
                    })
                } else {
                    let values = data!["values"] as! [String: Any]
                    let reason = values["reason"] as! String
                    if reason == WMConstants.errors[301] {
                        WMGlobal.showAlert(title: "", message: "Incorrect password!", target: self)
                    } else if reason == WMConstants.errors[302] {
                        WMGlobal.showAlert(title: "", message: "Account not found", target: self)
                    } else if reason == WMConstants.errors[303] {
                        WMGlobal.showAlert(title: "", message: "Account is not verified", target: self)
                    }
                }
            }
        })
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
