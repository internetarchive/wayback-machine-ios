//
//  ForgotVC.swift
//  WM
//
//  Created by Admin on 10/10/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit

class ForgotVC: WMBaseVC {

    @IBOutlet weak var txtEmail: SkyFloatingLabelTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onSubmitPressed(_ sender: Any) {
        
    }

}
